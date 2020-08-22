require 'opal'
require 'simple-wasm'

puts WebAssembly.libs["simple-wasm"].exported_func

require 'ffi'
module Simple
  extend FFI::Library

  ffi_lib "simple-wasm"
  attach_function :func, :exported_func, []
end

puts Simple.func
