require 'experiment-wasm'
require 'ffi'

module Experiment
  extend FFI::Library

  ffi_lib "experiment-wasm"

  attach_function :retpointer, [:pointer], :pointer
  attach_function :retfloat, [:float], :float
  attach_function :retdouble, [:double], :double
  attach_function :retstring, [:string], :string

  attach_function :longsize, [], :int
  attach_function :longlongsize, [], :int
  attach_function :ptrsize, [], :int
  attach_function :floatsize, [], :int
  attach_function :doublesize, [], :int
  attach_function :longdoublesize, [], :int

  attach_function :structalignld, [], :int
  attach_function :structalignll, [], :int
  attach_function :structaligni, [], :int
  attach_function :structalignp, [], :int
end
