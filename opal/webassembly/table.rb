module WebAssembly
  class Table < `WebAssembly.Table`
    include Enumerable

    def self.new(initial=1, maximum=100)
      `new WebAssembly.Table({initial: #{initial}, maximum: #{maximum}, element: "anyfunc"})`
    end

    def to_a
      Array(self)
    end

    def each(&block)
      self.to_a.each(&block)
    end

    def get(i)
      self.JS.get(i)
    end
    alias [] get

    def set(i, val)
      self.JS.set(i, val)
    end
    alias []= set

    def grow(by)
      self.JS.grow(by)
    end

    def length
      self.JS[:length]
    end
  end
end
