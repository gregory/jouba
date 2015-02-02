require 'spec_helper'

describe Jouba::Event do
  let(:key) { 'User.1' }
  let(:name) { 'created' }
  let(:data) { { fname: 'John', lname: 'Doe' } }
  let(:uuid) { UUID.new }
  let(:attributes) do
    { key: key, name: name, data: data }
  end

  subject { described_class.new(attributes) }

  describe '.new(attributes)' do
    before do
      allow(UUID).to receive(:new).at_least(:once).and_return(uuid)
    end

    it 'sets the attributes and sets defaults for the other values' do
      expect(subject.uuid).to eq uuid.to_s
      expect(subject.version).to eq uuid.version
      expect(subject.timestamp).to eq uuid.timestamp
      expect(subject.key).to eq key
      expect(subject.name).to eq name
      expect(subject.data).to eq data
    end
  end

  describe '.serialize(event)' do
    before do
      allow(UUID).to receive(:new).at_least(:once).and_return(uuid)
    end

    let(:event) { described_class.new(attributes) }
    let(:expected_serialized) do
      {
        key: key,
        name: name,
        data: data,
        uuid: uuid.to_s,
        version: uuid.version,
        timestamp: uuid.timestamp
      }
    end

    subject { described_class.serialize(event) }

    it 'serializes into a hash' do
      expect(subject).to eq expected_serialized
    end
  end

  describe '.deserialize(serialized_event)' do
    let(:event) { described_class.new(attributes) }
    let(:serialized_event) { described_class.serialize(event) }
    subject { described_class.deserialize(serialized_event) }

    it 'rebuild an event based on the serialized version' do
      expect(subject).to eq event
    end
  end

  describe '.stream(key, params)' do
    let(:stream) { [described_class.new(attributes), described_class.new(attributes)] }
    let(:key) { 'key' }
    let(:params) { { lname: 'foo' } }
    let(:serialized_stream) { stream.map { |item| described_class.serialize(item) } }

    before { expect(Jouba.Store).to receive(:get).with(key, params).and_return(serialized_stream) }

    it 'returns a stream of events' do
      expect(described_class.stream(key, params)).to eq stream
    end
  end

  describe '#track' do
    let(:event) { described_class.new(attributes) }
    let(:serialized_event) { described_class.serialize(event) }
    before { expect(Jouba.Store).to receive(:set).with(event.key, serialized_event) }

    it 'persist an event in the store' do
      event.track
    end
  end
end
