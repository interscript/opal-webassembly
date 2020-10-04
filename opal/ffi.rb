require 'webassembly'

# An API trying to be compatible with Ruby-FFI.
module FFI
  def self.contexts
    (@contexts ||= [])
  end

  def self.context
    (@contexts ||= []).last.tap do |lib|
      unless lib
        raise RuntimeError, "This call needs to be done in a FFI::Library#context "+
                            "block (Opal-WebAssembly limitation)."
      end
    end
  end
end

require 'ffi/types'
require 'ffi/pointer'
require 'ffi/struct'
require 'ffi/library'
