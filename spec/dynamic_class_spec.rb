require 'spec_helper'

describe DynamicClass do
  it 'has a version number' do
    expect(DynamicClass::VERSION).not_to be nil
  end

  it 'does something useful' do
    expect(false).to eq(true)
  end
end
