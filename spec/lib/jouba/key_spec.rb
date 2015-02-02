require 'spec_helper'

describe Jouba::Key do
  let(:name) { 'Customer' }
  let(:id) { '1' }
  let(:key) { 'Customer.1' }

  describe '.serialize(name, id)' do
    subject { described_class.serialize(name, id) }

    it 'serialize a name and id' do
      expect(subject).to eq key
    end
  end

  describe '.deserialize(key)' do
    subject { described_class.deserialize(key) }

    it 'deserialize a key into name an id' do
      expect(subject.name).to eq name
      expect(subject.id).to eq id
    end

    context 'when there is more information in the key' do
      let(:key) { 'Customer.1.meta.info' }
      it 'parse the key properly' do
        expect(subject.name).to eq name
        expect(subject.id).to eq id
      end
    end
  end
end
