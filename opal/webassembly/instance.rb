require 'native'

module WebAssembly
  class Instance < `WebAssembly.Instance`
    def self.new(mod, imports={})
      `new WebAssembly.Instance(#{mod}, #{imports.to_n})`
    end

    def exports
      Native::Object.new(`self.exports`)
    end

    def method_missing meth, *args
      exports[meth].call(*args)
    end
  end
end
