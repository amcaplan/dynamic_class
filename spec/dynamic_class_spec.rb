require 'spec_helper'
require 'ostruct'

describe DynamicClass do
  subject { klass.new(data) }

  let(:klass) { described_class.new }
  let(:data) {{}} # default, overridden in many tests

  def expect_subject_responds(attribute)
    expect(subject).to respond_to(attribute)
    expect(subject).to respond_to(:"#{attribute}=")
  end

  def expect_subject_does_not_respond(attribute)
    expect(subject).not_to respond_to(attribute)
    expect(subject).not_to respond_to(:"#{attribute}=")
  end


  describe 'setting and getting values' do
    context 'setting at initialization' do
      let(:data) {{ foo: 'bar' }}

      it 'retrieves via getter method' do
        expect(subject.foo).to eq('bar')
      end

      it 'retrieves via [] method with Symbol' do
        expect(subject[:foo]).to eq('bar')
      end

      it 'retrieves via [] method with String' do
        expect(subject['foo']).to eq('bar')
      end
    end

    context 'setting after initialization' do
      let(:value) { double(:value) }

      context 'setting with attr= methods' do
        it 'returns the input value' do
          expect(subject.foo = value).to eq(value)
        end

        it 'sets the value' do
          subject.foo = value
          expect(subject.foo).to eq(value)
        end
      end

      context 'setting with []= method' do
        it 'returns the input value' do
          expect(subject[:foo] = value).to eq(value)
        end

        it 'sets the value' do
          subject[:foo] = value
          expect(subject.foo).to eq(value)
        end
      end
    end
  end

  describe 'append-only method signature' do
    it 'does not respond to getters and setters by default' do
      expect_subject_does_not_respond(:foo)
    end

    it 'appends getters and setters in response to setting a value at initialization' do
      klass.new(foo: 'bar')
      expect_subject_responds(:foo)
    end

    describe 'appending getters and setters in response to setting a value after initialization' do
      it 'appends in response to a = method' do
        subject.foo = 'bar'
        expect_subject_responds(:foo)
      end

      it 'appends in response to the []= method with a Symbol' do
        subject[:foo] = 'bar'
        expect_subject_responds(:foo)
      end

      it 'appends in response to the []= method with a String' do
        subject['foo'] = 'bar'
        expect_subject_responds(:foo)
      end
    end

    it 'does not append getters and setters in response to getting an attribute' do
      subject.foo
      expect_subject_does_not_respond(:foo)
    end

    it 'does not remove getters and setters when a field is deleted' do
      subject.foo = 'bar'
      subject.delete_field(:foo)
      expect_subject_responds(:foo)
    end

    describe 'not overwriting existing methods' do
      let(:klass) {
        DynamicClass.new do
          def bar=(value)
            @bar = value + 4
          end

          def foo
            @foo + 3
          end
        end
      }

      context 'on attributes set at initialization' do
        let(:data) {{ foo: 0, bar: 0 }}

        it 'uses the explicitly defined setter' do
          expect(subject.bar).to eq(4)
        end

        it 'uses the explicitly defined getter' do
          expect(subject.foo).to eq(3)
        end
      end

      context 'on attributes set after initialization' do
        before do
          subject.foo = 0
          subject.bar = 0
        end

        it 'uses the explicitly defined setter' do
          expect(subject.bar).to eq(4)
        end

        it 'uses the explicitly defined getter' do
          expect(subject.foo).to eq(3)
        end
      end
    end
  end

  describe 'equality testing' do
    let(:object1) { klass.new(data1) }
    let(:object2) { klass.new(data2) }

    context 'both objects are empty' do
      let(:data1) {{}}
      let(:data2) {{}}

      it 'considers the objects equal' do
        expect(object1).to eq(object2)
      end
    end

    context 'one object is empty' do
      let(:data1) {{}}
      let(:data2) {{ a: 'foo' }}

      it 'considers the objects unequal' do
        expect(object1).not_to eq(object2)
      end
    end

    context 'both objects hold the same data' do
      let(:data1) {{ a: 'foo' }}
      let(:data2) {{ a: 'foo' }}

      it 'considers the objects equal' do
        expect(object1).to eq(object2)
      end
    end

    context 'both objects have the same keys but different values' do
      let(:data1) {{ a: 'foo' }}
      let(:data2) {{ a: 'bar' }}

      it 'considers the objects unequal' do
        expect(object1).not_to eq(object2)
      end
    end

    context 'both objects have the same values but different keys' do
      let(:data1) {{ a: 'foo' }}
      let(:data2) {{ b: 'foo' }}

      it 'considers the objects unequal' do
        expect(object1).not_to eq(object2)
      end
    end
  end

  describe 'inputting and outputting hashes and hash-like objects' do
    let(:data) {{name: "John Smith", age: 70, pension: 300}}

    it 'outputs a hash equal to its input hash' do
      expect(subject.to_h).to eq(data)
    end

    it "accepts another #{described_class} instance instead of a hash on initialization" do
      expect(klass.new(subject).to_h).to eq(data)
    end

    it 'accepts a Struct instead of a hash on initialization' do
      struct = Struct.new(*data.keys).new(*data.values)
      expect(klass.new(struct).to_h).to eq(data)
    end

    it 'accepts an OpenStruct instead of a hash on initialization' do
      open_struct = OpenStruct.new(data)
      expect(klass.new(open_struct).to_h).to eq(data)
    end
  end

  describe 'accessing keys and values with #each_pair' do
    let(:data) {{ name: "John Smith", age: 70, pension: 300 }}

    it 'iterates through each pair' do
      pairs = data.each_pair
      subject.each_pair do |key, value|
        expect([key, value]).to eq(pairs.next)
      end
      expect { pairs.next }.to raise_error(StopIteration) # all values were seen
    end

    it 'returns the iterated hash' do
      expect(subject.each_pair{}).to eq(data)
    end
  end

  describe 'computing hash value' do
    let(:data) {{ name: "John Smith", age: 70, pension: 300 }}

    it 'uses the hash value of the internally built hash' do
      expect(subject.hash).to eq(data.hash)
    end
  end

  describe 'raising errors' do
    context 'including an argument on a getter which has not yet been created' do
      it 'raises an ArgumentError' do
        expect { subject.foo(true) }.to raise_error(ArgumentError)
      end
    end

    context 'including an extra argument on a setter which has not yet been created' do
      it 'raises an ArgumentError' do
        expect { subject.send(:foo=, 'bar', 'bar') }.to raise_error(ArgumentError)
      end
    end
  end

  describe 'relationship between instances of the same DynamicClass class' do
    it 'makes the same methods available to other instances of the same class' do
      expect_subject_does_not_respond(:foo)
      klass.new(foo: 'bar')
      expect_subject_responds(:foo)
    end
  end

  describe 'relationship between instances of different DynamicClass classes' do
    context 'the classes have no relationship' do
      let(:klass2) { DynamicClass.new }

      before do
        klass2.new(foo: 'bar')
        expect(klass2.new).to respond_to(:foo)
      end

      it 'does not impact an unrelated class' do
        expect_subject_does_not_respond(:foo)
      end
    end

    context 'one class inherits from the other' do
      let(:klass2) { Class.new(klass) }
      let(:child) { klass2.new }

      context 'an attribute is added to the parent' do
        before do
          subject.foo = 'bar'
          expect_subject_responds(:foo)
        end

        it 'inherits methods from a parent' do
          expect(child).to respond_to(:foo)
          expect(child).to respond_to(:foo=)
          expect(subject.to_h).to have_key(:foo)
        end

        it 'does not include attributes from the parent in output hash' do
          expect(child.to_h).not_to have_key(:foo)
        end
      end

      context 'an attribute is added to the child' do
        before do
          child.foo = 'bar'
          expect(child).to respond_to(:foo)
          expect(child).to respond_to(:foo=)
          expect(child.to_h).to have_key(:foo)
        end

        it 'does not pass methods up to the parent' do
          expect_subject_does_not_respond(:foo)
        end

        it 'does not include attributes from the child in output hash' do
          expect(subject.to_h).not_to have_key(:foo)
        end
      end
    end
  end

  describe 'freezing' do
    context 'subject is frozen' do
      before do
        subject.foo = 'bar'
        subject.freeze
      end

      it 'raises a RuntimeError when adding a new value' do
        expect { subject.baz = 'quux' }.to raise_error(RuntimeError)
      end

      it 'raises a RuntimeError when modifying a value' do
        expect { subject.foo = 'quux' }.to raise_error(RuntimeError)
      end
    end
  end

  describe 'custom class code' do
    context 'when a block is not specified' do
      let(:klass) { DynamicClass.new }

      it 'does not raise an error' do
        expect { klass.new }.not_to raise_error
      end
    end

    context 'when a block is specified' do
      let(:klass) {
        DynamicClass.new do
          def four
            4
          end
        end
      }

      it 'responds to methods defined in the passed-in block' do
        expect(subject.four).to eq(4)
      end
    end
  end

  describe 'thread-safety' do
    context 'adding keys in multiple threads' do
      before do
        500.times.map { |i|
          Thread.new do
            subject["foo#{i}"] = i
          end
        }.each(&:join)
      end

      it 'adds all the keys appropriately' do
        (0...500).each do |i|
          expect(subject).to respond_to(:"foo#{i}")
        end
      end

      it 'updates #to_h properly' do
        keys = (0...500).map { |i| :"foo#{i}" }
        expect(subject.to_h).to include(*keys)
      end
    end
  end
end
