experiment-wasm.wasm: experiment-wasm.c
	clang --target=wasm32 -Oz -flto -nostdlib -Wl,--no-entry -Wl,--export-all -Wl,--lto-O3 -Wl,-z,stack-size=8388608 -o $@ $<
