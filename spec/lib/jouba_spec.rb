require 'spec_helper'

describe Jouba do
  [:Key, :Event, :Cache, :Store].each do |meth|
    after { Jouba.send(meth) }
    it "delegates #{meth} to config" do
      expect(described_class.config).to receive(meth)
    end
  end
  describe '.config' do
    subject { described_class.config }

    it { should be_a Hashie::Mash }

    context 'by default' do
      subject { described_class.config[key] }

      context 'when key is event' do
        let(:key) { 'Event' }
        it { expect(subject).to eq Jouba::Event }
      end

      context 'when key is key' do
        let(:key) { 'Key' }
        it { expect(subject).to eq Jouba::Key }
      end

      context 'when key is cache' do
        let(:key) { 'Cache' }
        it { expect(subject).to be_a Jouba::Cache::Null }
      end

      context 'when key is key' do
        let(:key) { 'Store' }
        it { expect(subject).to be_a Jouba::EventStore }
      end
    end
  end

  describe '.emit(key, name, data)' do
    let(:key) { 'key' }
    let(:name) { 'name' }
    let(:data) { double(:data) }
    let(:event_payload) do
      { key: key, name: name, data: data }
    end
    let(:event) { Jouba::Event.new(event_payload) }

    after { described_class.emit(key, name, data) }

    it 'tracks a new event' do
      expect(Jouba.Event).to receive(:new).with(event_payload).and_return(event)
      expect(event).to receive(:track)
    end
  end

  describe '.stream(key, params)' do
    let(:key) { 'key' }
    let(:params) { { foo: 'bar' } }

    after { described_class.stream(key, params) }

    it 'returns the stream of events' do
      expect(Jouba.Event).to receive(:stream).with(key, params)
    end
  end
end
