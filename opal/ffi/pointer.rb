# Large portions of this file are adapted from
# https://github.com/ffi/ffi/blob/master/lib/ffi/pointer.rb

module FFI
  class Pointer
    SIZE = 4

    # Return the size of a pointer on the current platform, in bytes
    # @return [Numeric]
    def self.size
      SIZE
    end

    # @param [nil,Numeric] len length of string to return
    # @return [String]
    # Read pointer's contents as a string, or the first +len+ bytes of the
    # equivalent string if +len+ is not +nil+.
    def read_string(len=nil)
      if len
        return ''.b if len == 0
        get_bytes(0, len)
      else
        get_string(0)
      end
    end

    # @param [Numeric] len length of string to return
    # @return [String]
    # Read the first +len+ bytes of pointer's contents as a string.
    #
    # Same as:
    #  ptr.read_string(len)  # with len not nil
    def read_string_length(len)
      get_bytes(0, len)
    end

    # @return [String]
    # Read pointer's contents as a string.
    #
    # Same as:
    #  ptr.read_string  # with no len
    def read_string_to_null
      get_string(0)
    end

    # @param [String] str string to write
    # @param [Numeric] len length of string to return
    # @return [self]
    # Write +len+ first bytes of +str+ in pointer's contents.
    #
    # Same as:
    #  ptr.write_string(str, len)   # with len not nil
    def write_string_length(str, len)
      put_bytes(0, str, 0, len)
    end

    # @param [String] str string to write
    # @param [Numeric] len length of string to return
    # @return [self]
    # Write +str+ in pointer's contents, or first +len+ bytes if
    # +len+ is not +nil+.
    def write_string(str, len=nil)
      #len = str.bytesize unless len
      # Write the string data without NUL termination
      put_bytes(0, str, 0, len)
    end

    # @param [Type] type type of data to read from pointer's contents
    # @param [Symbol] reader method to send to +self+ to read +type+
    # @param [Numeric] length
    # @return [Array]
    # Read an array of +type+ of length +length+.
    # @example
    #  ptr.read_array_of_type(TYPE_UINT8, :read_uint8, 4) # -> [1, 2, 3, 4]
    def read_array_of_type(type, reader, length)
      ary = []
      size = FFI.type_size(type)
      tmp = self
      length.times { |j|
        ary << tmp.send(reader)
        tmp += size unless j == length-1 # avoid OOB
      }
      ary
    end

    # @param [Type] type type of data to write to pointer's contents
    # @param [Symbol] writer method to send to +self+ to write +type+
    # @param [Array] ary
    # @return [self]
    # Write +ary+ in pointer's contents as +type+.
    # @example
    #  ptr.write_array_of_type(TYPE_UINT8, :put_uint8, [1, 2, 3 ,4])
    def write_array_of_type(type, writer, ary)
      size = FFI.type_size(type)
      ary.each_with_index { |val, i|
        break unless i < self.size
        self.send(writer, i * size, val)
      }
      self
    end

    # @return [self]
    def to_ptr
      self
    end

    def pointer
      self
    end

    # @param [Symbol,Type] type of data to read
    # @return [Object]
    # Read pointer's contents as +type+
    #
    # Same as:
    #  ptr.get(type, 0)
    def read(type)
      get(type, 0)
    end

    # @param [Symbol,Type] type of data to read
    # @param [Object] value to write
    # @return [nil]
    # Write +value+ of type +type+ to pointer's content
    #
    # Same as:
    #  ptr.put(type, 0)
    def write(type, value)
      put(type, 0, value)
    end

    def get_bytes(pos, len)
      ary = @memory.buffer.to_a

      out = []
      i = 0
      while i < len
        out << ary[@address + pos + i]
        i += 1
      end

      # We expect a binary string as an output of this function.
      out.pack("c*").b # TODO upstream: #bytes is wrong!
    end

    def put_bytes(pos, src, src_pos=0, len=nil)
      if src.respond_to? :bytes
        src = if src.encoding == Encoding::BINARY
          src.chars.map(&:ord)
        else
          src.bytes
        end
      end
      len ||= src.length - src_pos

      ary = @memory.buffer.to_a
      i = 0
      while i < len
        ary[@address + i + pos] = src[src_pos + i]
        i += 1
      end
    end

    def get(type, pos)
      type = FFI::Type[type]
      bytes = get_bytes(pos, type.size)
      if type.respond_to? :from_native_mem
        type.from_native_mem(type.unpack(bytes), @memory)
      else
        type.from_native(type.unpack(bytes))
      end
    end

    def put(type, pos, value)
      type = FFI::Type[type]
      value = if type.respond_to? :to_native_mem
        type.to_native_mem(value, @memory)
      else
        type.to_native(value)
      end
      value = type.pack(value)
      put_bytes(pos, value)
    end

    def get_string(pos)
      out = []
      ary = @memory.buffer.to_a
      pos += @address
      loop do
        byte = ary[pos]
        break if byte == 0
        out << byte
        pos += 1
      end
      out.pack("c*").b
    end

    def put_string(pos, string)
      put_bytes(pos, string)
    end

    def self.from_string src
      bs = if src.encoding == Encoding::BINARY
        src.chars.map(&:ord)
      else
        src.bytes
      end
      bs = bs + [0, 0]
      out = new(:uint8, bs.count)
      out.put_bytes(0, bs)
      out
    end

    def self.alloc_out size, count, smh=false
      new(:uint8, size*count)
    end

    def self.alloc_in size, count, smh=false
      new(:uint8, size*count)
    end

    def method_missing method, *args
      method = method.to_s
      super
    end

    # Pointer in our case is more complex than a regular one: it's
    # [WebAssembly::Memory instance, uint32 address] since WebAssembly
    # "processes" run in separate address spaces.
    #
    # Alternatively, memory can be deduced from wrapping inside
    # Library#context.
    def initialize(address, type=nil, size=nil)
      if address.respond_to? :address
        if address.respond_to? :memory
          @memory = address.memory || FFI.context.library.memory
        else
          @memory = FFI.context.library.memory
        end
        @address = address.address
      elsif address.respond_to?(:to_sym) || address.is_a?(Type) || address.is_a?(Class) # Allocation call
        type, count = address, type
        @memory = FFI.context.library.memory
        @address = FFI.context.malloc(FFI::Type[type].size * (count || 1)).address
      elsif address.respond_to? :to_ary
        @memory, @address = address.to_ary
        @size = size
      elsif address.respond_to? :to_int
        @memory = FFI.context.library.memory
        @address = address.to_int
        @size = size
      else
        raise TypeError, "Address has an invalid type"
      end
      @type = type ? FFI::Type[type] : FFI::Type[:uint8]
    end

    attr_accessor :memory, :address, :type

    def == other
      (self.address == other.address) &&
      (self.address == 0 || (self.memory == other.memory))
    end

    def + offset
      self.dup.tap { |i| i.address += offset * type.size }
    end

    def [] offset
      self.get(type, offset * type.size)
    end

    def []= offset, value
      self.put(type, offset * type.size, value)
    end

    NULL = new([nil, 0])
  end

  AutoPointer = MemoryPointer = Buffer = Pointer
end
