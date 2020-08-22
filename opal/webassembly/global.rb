module WebAssembly
  class Global < `WebAssembly.Global`
    def self.new(value, type="i32", mutable=true)
      `new WebAssembly.Global({value: #{type}, mutable: #{mutable}}, #{value})`
    end

    def value
      self.JS[:value]
    end

    def value= new_val
      self.JS[:value] = new_val
    end
  end
end
