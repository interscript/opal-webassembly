require 'webassembly'

# An API trying to be compatible with Ruby-FFI.
module FFI
  def self.utf8_fill_buffer
  end

  def self.utf8_load_buffer
  end
end

require 'ffi/library'
require 'ffi/pointer'
require 'ffi/struct'
require 'ffi/types'
