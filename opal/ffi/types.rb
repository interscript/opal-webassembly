module FFI
  TypeDefs = {}

  # TODO: clean me up
  class Type
    def self.alignment; size; end

    class Numeric < self
      def self.signed; false; end
      def self.pack(x)
        [x].pack(packformat).b
      end
      def self.unpack(x)
        x.unpack(packformat.b).first
      end
    end

    class Integer < Numeric
      def self.from_native(x); x.to_i; end
      def self.to_native(x); x.to_i; end

      def self.packformat
        case self.size
        when 1
          signed ? "c" : "C"
        when 2
          signed ? "s<" : "S<"
        when 4
          signed ? "l<" : "L<"
        when 8
          signed ? "q<" : "Q<"
        end
      end
    end

    class Float < Numeric
      def self.from_native(x); x.to_f; end
      def self.to_native(x); x.to_f; end

      # Unfortunately, that is not supported by Opal. TODO: Upstream fix
      def self.packformat
        case self.size
        when 2
          "e"
        when 4
          "E"
        when 8
          raise TypeError, "We can't pack/unpack a long double unfortunately."
        end
      end
    end

    class VOID < self
      def self.size; 1; end
      def self.from_native(x); nil; end
      def self.to_native(x); raise TypeError, "Can't convert VOID to a native value"; end
      def self.pack(x); ""; end
      def self.unpack(x); nil; end
    end

    class BOOL < self
      def self.size; 1; end
      def self.from_native(x); !!x; end
      def self.to_native(x); x ? 1 : 0; end
      def self.pack(x); x ? "\1" : "\0"; end
      def self.unpack(x); x != "\0"; end
    end

    class POINTER < Integer
      def self.size; 4; end

      def self.from_native_mem(x, memory)
        Pointer.new([memory, x])
      end

      def self.to_native(x)
        if !x
          0
        elsif x.respond_to? :value # WebAssembly::Global?
          x.value
        elsif x.respond_to? :address # Struct? Pointer?
          x.address
        elsif x.respond_to? :to_int # Integer?
          x.to_int
        elsif x.respond_to? :to_str # String? It leaks though.
          FFI::Pointer.from_string(x.to_str).address
        else
          raise ArgumentError, "Wrong argument #{x} can't be coerced to a pointer."
        end
      end
    end

    # TODO: Implement DataConverter
    class WrappedStruct < self
      def alignment; FFI::Type::POINTER.alignment; end
      def size; FFI::Type::POINTER.size; end
      def pack x; FFI::Type::POINTER.pack(x); end
      def unpack x; FFI::Type::POINTER.unpack(x); end

      def initialize x
        @struct = x
      end

      def from_native_mem(x, memory)
        @struct.new(FFI::Pointer.new([memory, x], @struct))
      end

      def to_native(x)
        x.pointer.address
      end
    end

    class STRING < self
      def self.size; 4; end

      def self.from_native_mem(x, memory)
        FFI::Pointer.new([memory, x]).read_string
      end

      # WARNING: it leaks!
      def self.to_native x
        FFI::Pointer.from_string(x).address
      end

      def self.pack x; x.to_s; end
      def self.unpack x; x.to_s; end
    end

    class CHAR < Integer; def self.size; 1; end; def self.signed; true; end; end
    class UCHAR < Integer; def self.size; 1; end; end
    class SHORT < Integer; def self.size; 2; end; def self.signed; true; end; end
    class USHORT < Integer; def self.size; 2; end; end
    class INT < Integer; def self.size; 4; end; def self.signed; true; end; end
    class UINT < Integer; def self.size; 4; end; end
    class LONG < INT; end
    class ULONG < INT; end
    class LONG_LONG < Integer; def self.size; 8; end; def self.signed; true; end; end
    class ULONG_LONG < Integer; def self.size; 8; end; end
    class FLOAT < Float; def self.size; 4; end; end
    class DOUBLE < Float; def self.size; 8; end; end
    class LONG_DOUBLE < Float; def self.size; 16; end; end

    class INT8 < CHAR; end
    class UINT8 < CHAR; end
    class INT16 < SHORT; end
    class UINT16 < USHORT; end
    class INT32 < INT; end
    class UINT32 < UINT; end
    class INT64 < LONG_LONG; end
    class UINT64 < ULONG_LONG; end

    def self.[] name, purpose = nil
      FFI.find_type name, purpose: purpose
    end
  end

  def self.typedef old, new
    TypeDefs[new] = find_type(old)
  end

  def self.add_typedef(old, new); typedef old, new; end

  def self.find_type name, type_map = nil, purpose: nil
    if name.is_a?(FFI::Type) || (name.is_a?(Class) && name <= FFI::Type)
      name
    elsif type_map && type_map.has_key?(name)
      type_map[name]
    elsif TypeDefs.has_key?(name)
      TypeDefs[name]
    elsif name.is_a?(Class) && name <= FFI::Struct
      if purpose == nil
        Type::WrappedStruct.new(name)
      elsif purpose == :struct
        name
      else
        raise ArgumentError, "Wrong purpose provided. Can't resolve type '#{name}'."
      end
    else
      raise TypeError, "unable to resolve type '#{name}'"
    end
  end

  def self.type_size name
    find_type(name).size
  end

  typedef Type::VOID, nil

  typedef Type::VOID, :void
  typedef Type::BOOL, :bool
  typedef Type::CHAR, :char
  typedef Type::UCHAR, :uchar
  typedef Type::SHORT, :short
  typedef Type::USHORT, :ushort
  typedef Type::INT, :int
  typedef Type::UINT, :uint
  typedef Type::LONG, :long
  typedef Type::ULONG, :ulong
  typedef Type::LONG_LONG, :long_long
  typedef Type::ULONG_LONG, :ulong_long
  typedef Type::FLOAT, :float
  typedef Type::DOUBLE, :double
  typedef Type::LONG_DOUBLE, :long_double

  typedef Type::INT8, :int8
  typedef Type::UINT8, :uint8
  typedef Type::INT16, :int16
  typedef Type::UINT16, :uint16
  typedef Type::INT32, :int32
  typedef Type::UINT32, :uint32
  typedef Type::INT64, :int64
  typedef Type::UINT64, :uint64

  typedef Type::POINTER, :pointer
  typedef Type::STRING, :string

  typedef :uint8, :byte
  typedef :long, :size_t

  typedef :pointer, :buffer_in
  typedef :pointer, :buffer_out
  typedef :pointer, :buffer_inout

  # varargs and strptr are not currently supported
  # same with enums.
end
