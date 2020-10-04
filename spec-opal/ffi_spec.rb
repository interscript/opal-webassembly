require 'spec_helper'
require 'experiment'

RSpec.describe FFI do
  it "has correct assumptions about types (wasm32)" do
    expect(Experiment.longsize).to eq FFI::Type[:long].size
    expect(Experiment.longlongsize).to eq FFI::Type[:long_long].size
    expect(Experiment.ptrsize).to eq FFI::Type[:pointer].size
    expect(Experiment.floatsize).to eq FFI::Type[:float].size
    expect(Experiment.doublesize).to eq FFI::Type[:double].size
    expect(Experiment.longdoublesize).to eq FFI::Type[:long_double].size
  end

  it "has correct assumptions about struct alignment" do
    expect(Experiment.structalignld).to eq FFI::Type[:long_double].alignment
    expect(Experiment.structalignll).to eq FFI::Type[:long_long].alignment
    expect(Experiment.structaligni).to eq FFI::Type[:int].alignment
    expect(Experiment.structalignp).to eq FFI::Type[:pointer].alignment
  end

  it "passes pointers correctly" do
    ptr = Experiment.retpointer(FFI::Pointer.new([nil, 0x1133dd]))
    expect(ptr.address).to eq(0x1133dd)
    expect(ptr.memory).to eq(Experiment.library.memory)
  end

  it "passes floats correctly" do
    expect(Experiment.retfloat(0.11)).to be_within(0.00001).of(-0.22)
    expect(Experiment.retdouble(0.33)).to be_within(0.00000001).of(-0.66)
  end

  it "passes strings correctly" do
    require 'corelib/array/pack'
    Experiment.context do
      expect(Experiment.retstring("hello world!".b)).to be("lmo!world!")
    end
  end

  it "packs and unpacks values correctly" do
    require 'corelib/array/pack'
    require 'corelib/string/unpack'
    for type in %i[uint8 int8 uint16 int16 int32 uint32 pointer]
      type = FFI::Type[type]
      expect(type.unpack(type.pack(123))).to eq(123)
    end
    type = FFI::Type[:string]
    expect(type.unpack(type.pack(123))).to eq("123")
  end

  it "supports structs" do
    require 'corelib/array/pack'
    require 'corelib/string/unpack'

    class MyStr < FFI::Struct
      layout :a, :char,
             :b, :int,
             :c, [:int, 20]
    end

    Experiment.context do
      expect(MyStr.members[:a].offset).to eq(0)
      expect(MyStr.members[:b].offset).to eq(4)
      expect(MyStr.members[:c].offset).to eq(8)

      str = MyStr.new

      expect(str[:c]).to be_a(FFI::Pointer)
      expect(str[:a]).to be_a(Integer)

      str[:a] = 10
      str[:c][4] = 2000000

      expect(str[:a]).to eq(10)
      expect(str[:c][4]).to eq(2000000)

      expect(MyStr.size).to eq(22 * 4)
    end
  end

  it "supports nested pointer structs" do
    require 'corelib/array/pack'
    require 'corelib/string/unpack'

    class Struct2 < FFI::Struct
      layout :age, :int,
             :a, :int,
             :b, :int,
             :c, :int
    end

    class Struct1 < FFI::Struct
      layout :id, :int,
             :data, Struct2.ptr
    end

    Experiment.context do
      expect(Struct2.size).to eq(16)
      expect(Struct1.size).to eq(8)

      struct = Struct1.new
      struct2 = Struct2.new
      struct[:data] = struct2
      struct[:data][:age] = 27

      expect(struct).to be_a(Struct1)
      expect(struct[:data]).to be_a(Struct2)
      expect(struct[:data][:age]).to eq(27)
    end
  end

  it "supports nested structs" do
    require 'corelib/array/pack'
    require 'corelib/string/unpack'

    class Struct4 < FFI::Struct
      layout :age, :int,
             :a, :int,
             :b, :int,
             :c, :int
    end

    class Struct3 < FFI::Struct
      layout :id, :int,
             :data, Struct4
    end

    Experiment.context do
      expect(Struct4.size).to eq(16)
      expect(Struct3.size).to eq(20)

      struct = Struct3.new
      struct[:data][:age] = 27

      expect(struct).to be_a(Struct3)
      expect(struct[:data]).to be_a(Struct4)
      expect(struct[:data][:age]).to eq(27)
    end
  end
end
