module FFI
  class Struct
    def self.size
      @size || 4
    end

    def self.alignment
      @alignment ||= @layout&.values&.map(&:type)&.map(&:alignment)&.max || 4
    end

    def self.by_value; self; end
    def self.by_ptr; FFI::Type::WrappedStruct.new(self); end

    def self.pack x; raise ArgumentError, "Packing Struct directly is forbidden"; end
    def self.unpack x; raise ArgumentError, "Unpacking Struct directly is forbidden"; end

    def from_native_mem(x, memory)
      new(FFI::Pointer.new([memory, x], self))
    end

    def to_native(x)
      x.pointer.address
    end

    def self.ptr; by_ptr; end

    def self.layout *fs, **fields
      if fs.length > 0
        while (z = fs.shift(2)).length == 2
          k, v = z
          fields[k] = v
        end
      end

      offset = 0
      @layout = {}
      fields.each do |name, type|
        count = nil
        if type.is_a? Array
          type, count = type
        end
        type = FFI::Type[type, :struct]

        offset += 1 until (offset % type.alignment) == 0
        @layout[name] = Field.new(self, name, type, offset, count)

        if count
          offset += type.size * count
        else
          offset += type.size
        end
      end
      @size = offset
    end

    def self.members; @layout; end
    def members; self.class.members; end

    def [] field
      members[field].get(self)
    end

    def []= field, value
      members[field].set(self, value)
    end

    def offset_of field
      members[field].offset
    end

    attr_reader :pointer

    def address
      pointer.address
    end

    def initialize pointer=nil
      if pointer
        @pointer = pointer
      else
        @pointer = FFI.context.malloc(self.class.size)
        @pointer.type = FFI::Type[self.class]
        @pointer
      end
    end

    def free
      @pointer.free
    end

    def inspect
      out = ["#<#{self.class.name}:#{"0x%08x" % self.address}: "]
      out << self.members.keys.map do |key|
        ":#{key} => #{self.[](key).inspect}"
      end.join(", ")
      out << ">"
      out.join
    end
  end

  class Field
    attr_accessor :struct, :name, :type, :offset, :count
    def initialize struct, name, type, offset, count
      @struct, @name, @type, @offset, @count = struct, name, type, offset, count
    end

    def get from
      if count
        FFI::Pointer.new([from.pointer.memory, from.address + offset], type)
      elsif type.is_a?(Class) && type <= FFI::Struct
        type.new(FFI::Pointer.new([from.pointer.memory, from.address + offset], type))
      else
        from.pointer.get(type, offset)
      end
    end

    def set from, value
      if count
        raise ArgumentError, "Can't set an array #{name} of #{struct}."
      elsif type.is_a?(Class) && type <= FFI::Struct
        raise ArgumentError, "Can't set a nested struct #{name}."
      else
        from.pointer.put(type, offset, value)
      end
    end
  end

  ManagedStruct = Struct
end
