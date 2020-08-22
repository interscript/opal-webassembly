(module
  (func $exported_func (result i32)
    i32.const 42
    return
  )

  (export "exported_func" (func $exported_func))
)
