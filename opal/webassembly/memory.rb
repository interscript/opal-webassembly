require 'buffer'

module WebAssembly
  class Memory < `WebAssembly.Memory`
    # 64kB pages
    def self.new(initial=1, maximum=100, shared=false)
      `new WebAssembly.Memory({initial: #{initial}, maximum: #{maximum}, shared: #{shared}})`
    end

    def grow(by)
      self.JS.grow(by)
    end

    def buffer
      Buffer.new(self.JS[:buffer])
    end
  end
end
