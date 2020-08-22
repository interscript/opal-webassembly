require 'native'

module WebAssembly
  class Module < `WebAssembly.Module`
    def self.new(buffer)
      buffer = buffer.to_n unless native? buffer
      `new WebAssembly.Module(#{buffer})`
    end
  end
end
