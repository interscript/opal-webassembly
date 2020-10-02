module FFI
  module Library
    def self.extended(mod)
      raise RuntimeError.new("must only be extended by module") unless mod.kind_of?(Module)
    end

    def ffi_lib(*names)
      # Expect the libraries to be already loaded in "Opal.WebAssembly.modules"
      @ffi_libs = names.map do |name|
        lib = WebAssembly.libs[name]
        raise LoadError, "Library #{lib} not loaded" if !lib
        lib
      end
    end

    def attach_function(name, func, args, returns = nil, options = nil)
      lib = @ffi_libs.find do |lib|
        lib.exports.has_key?(func)
      end
      raise LoadError, "No library responds to #{func}" if !lib
      fun = lib.exports[func]

      self.define_singleton_method name do |*as|
        if as.count != args.count # :varargs?
          raise ArgumentError, "Provided #{as.count} arguments, expected #{args.count}"
        end

        as = as.each_with_index.map do |a,ind|
          type = Type[args[ind]]
          if type.respond_to :to_native_mem
            type.to_native_mem(a, lib.memory)
          else
            type.to_native(a)
          end
        end

        ret = fun.call(*as)
        type = Type[returns]
        if type.respond_to :from_native_mem
          type.from_native_mem(ret, lib.memory)
        else
          type.from_native(ret)
        end
      end
    end
  end
end
