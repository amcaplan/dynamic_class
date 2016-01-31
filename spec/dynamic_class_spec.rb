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
      expect(subject.each_pair.to_a).to eq(data.each_pair.to_a)
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
end
