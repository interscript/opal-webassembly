module FFI
  module Library
    def self.extended(mod)
      raise RuntimeError.new("must only be extended by module") unless mod.kind_of?(Module)
    end

    def ffi_lib(*names)
      # Expect the library (first one) to be already loaded in "Opal.WebAssembly.modules"
      @ffi_lib = WebAssembly.libs[names.first]
      raise LoadError, "Library #{names.first} not loaded" if !@ffi_lib

      begin
        attach_function :malloc, [:long], :pointer
        attach_function :free, [:pointer], :void
        attach_function :realloc, [:pointer, :long], :pointer
      rescue LoadError
        # It's ok, a library doesn't really need to provide memory functions.
        # But we will need those.
      end
    end

    def library
      @ffi_lib
    end

    def attach_function(name, func, args = nil, returns = nil, **options)
      if func.is_a? Array # Don't rename a function
        func, args, returns = name, func, args
      end

      raise LoadError, "No library responds to #{func}" unless @ffi_lib.exports.has_key?(func)
      fun = @ffi_lib.exports[func]

      self.define_singleton_method name do |*as|
        if as.count != args.count # :varargs?
          raise ArgumentError, "Provided #{as.count} arguments, expected #{args.count}"
        end

        as = as.each_with_index.map do |a,ind|
          type = Type[args[ind]]
          if type.respond_to? :to_native_mem
            type.to_native_mem(a, @ffi_lib.memory)
          else
            type.to_native(a)
          end
        end

        ret = fun.call(*as)
        type = Type[returns]
        if type.respond_to? :from_native_mem
          type.from_native_mem(ret, @ffi_lib.memory)
        else
          type.from_native(ret)
        end
      end
    end

    # Launch a block in a current context. Needed for memory management.
    # Think: segmented memory.
    def context &block
      FFI.contexts.push self
      out = yield
      FFI.contexts.pop
      out
    end
  end
end
