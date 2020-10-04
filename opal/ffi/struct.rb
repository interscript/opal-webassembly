module FFI
  class Struct
    def self.size
      @size || 4
    end

    # WebAssembly by_value == by_ptr
    def self.by_value; self; end
    def self.by_ptr; self; end

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
        type = FFI::Type[type]

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
  end

  class Field
    attr_accessor :struct, :name, :type, :offset, :count
    def initialize struct, name, type, offset, count
      @struct, @name, @type, @offset, @count = struct, name, type, offset, count
    end

    def get from
      if count
        FFI::Pointer.new([from.pointer.memory, from.address + offset], type)
      else
        from.pointer.get(type, offset)
      end
    end

    def set from, value
      if count
        raise ArgumentError, "Can't set an array #{name} of #{struct}."
      else
        from.pointer.put(type, offset, value)
      end
    end
  end

  ManagedStruct = Struct
end
