module FFI
  class Struct
    def self.size
    end

    # WebAssembly by_value == by_ptr
    def self.by_value
      self
    end

    def self.by_ptr
      self
    end

    def self.layout *fields
    end

    def initialize pointer
    end
  end

  class ManagedStruct < Struct
    # Not implemented
  end
end
