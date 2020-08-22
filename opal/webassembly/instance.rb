require 'native'

module WebAssembly
  class Instance < `WebAssembly.Instance`
    include Enumerable

    def self.new(mod, imports={})
      `new WebAssembly.Instance(#{mod}, #{imports.to_n})`
    end

    def exports
      @exports_cache ||= {}.tap do |hash|
        %x{
          var hasOwnProperty = Object.prototype.hasOwnProperty.bind(#{self}.exports);
          for (var key in #{self}.exports) {
            if (hasOwnProperty(key)) {
              #{hash[`key`] = `#{self}.exports[key]`}
            }
          }
        }
      end
    end

    def method_missing meth, *args
      exports[meth].call(*args)
    end

    def [] export
      exports[export]
    end

    def to_h
      exports
    end

    def each(&block)
      exports.each(&block)
    end
  end
end
