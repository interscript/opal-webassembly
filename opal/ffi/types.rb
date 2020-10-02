module FFI
  TypeDefs = {}

  class Type
    class Integer
      def self.from_native(x); x.to_i; end
      def self.to_native(x); x.to_i; end
    end

    class Float
      def self.from_native(x); x.to_f; end
      def self.to_native(x); x.to_f; end
    end

    class VOID
      def self.size; 1; end
      def self.from_native(x); nil; end
      def self.to_native(x); raise TypeError, "Can't convert VOID to a native value"; end
    end

    class BOOL
      def self.size; 1; end
      def self.from_native(x); !!x; end
      def self.to_native(x); x ? 1 : 0; end
    end

    class POINTER
      def self.size 8; end
      def self.from_native_mem(x, memory); Pointer.new([memory, x]); end
      def self.to_native(x); x.address; end
    end

    class STRING; def self.size; 4; end; end
    class CHAR < Integer; def self.size; 1; end; end
    class UCHAR < Integer; def self.size; 1; end; end
    class SHORT < Integer; def self.size; 2; end; end
    class USHORT < Integer; def self.size; 2; end; end
    class INT < Integer; def self.size; 4; end; end
    class UINT < Integer; def self.size; 4; end; end
    class LONG < INT; end
    class ULONG < INT; end
    class LONG_LONG < Integer; def self.size; 8; end; end
    class ULONG_LONG < Integer; def self.size; 8; end; end
    class FLOAT < Float; def self.size 4; end; end
    class DOUBLE < Float; def self.size 8; end; end
    class LONG_DOUBLE < Float; def self.size 10; end; end

    class INT8 < CHAR; end
    class UINT8 < CHAR; end
    class INT16 < SHORT; end
    class UINT16 < USHORT; end
    class INT32 < INT; end
    class UINT32 < UINT; end
    class INT64 < LONG_LONG; end
    class UINT64 < ULONG_LONG; end

    def self.[] name
      FFI.find_type name
    end
  end

  def self.typedef old, new
    TypeDefs[new] = find_type(old)
  end

  def self.add_typedef(old, new); typedef old, new; end

  def self.find_type name, type_map = nil
    if name.is_a?(Type) || name < Type
      name
    elsif type_map && type_map.has_key?(name)
      type_map[name]
    elsif TypeDefs.has_key?(name)
      TypeDefs[name]
    else
      raise TypeError, "unable to resolve type '#{name}'"
    end
  end

  def self.type_size name
    find_type(name).size
  end

  typedef nil, Type::VOID

  typedef :void, Type::VOID
  typedef :bool, Type::BOOL
  typedef :char, Type::CHAR
  typedef :uchar, Type::UCHAR
  typedef :short, Type::SHORT
  typedef :ushort, Type::USHORT
  typedef :int, Type::INT
  typedef :uint, Type::UINT
  typedef :long, Type::LONG
  typedef :ulong, Type::ULONG
  typedef :long_long, Type::LONG_LONG
  typedef :ulong_long, Type::ULONG_LONG
  typedef :float, Type::FLOAT
  typedef :double, Type::DOUBLE
  typedef :long_double, Type::LONG_DOUBLE

  typedef :int8, Type::INT8
  typedef :uint8, Type::UINT8
  typedef :int16, Type::INT16
  typedef :uint16, Type::UINT16
  typedef :int32, Type::INT32
  typedef :uint32, Type::UINT32
  typedef :int64, Type::INT64
  typedef :uint64, Type::UINT64
end
