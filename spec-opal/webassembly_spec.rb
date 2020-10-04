require 'spec_helper'
require 'simple-wasm'

RSpec.describe WebAssembly do
  it "loads a WebAssembly module correctly" do
    expect(WebAssembly.libs["simple-wasm"]).to be_a(WebAssembly::Instance)
  end

  it "calls a function correctly" do
    expect(WebAssembly.libs["simple-wasm"].exported_func).to eq(42)
  end
end
