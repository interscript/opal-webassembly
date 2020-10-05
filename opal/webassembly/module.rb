require 'native'

module WebAssembly
  class CantLoadSyncError < StandardError; end

  class Module < `WebAssembly.Module`
    def self.new(buffer)
      buffer = buffer.to_n unless native? buffer
      %x{
        try {
          return new WebAssembly.Module(#{buffer});
        } catch(e) {
          if (e.name == "RangeError") {
            #{raise WebAssembly::CantLoadSyncError}
          }
          else throw e;
        }
      }
    end
  end
end
