require 'spec_helper'
require 'jouba/aggregate'

describe Jouba::Aggregate do
  let(:uuid) { '123' }
  let(:attributes) { { name: 'bar' }  }
  let(:name) { :created }
  let(:event) { Jouba::Event.new(key: target.to_key, name: name, data: attributes) }
  let(:listener) { double(:listener) }

  let(:target_class) do
    Class.new(OpenStruct) do
      include Jouba::Aggregate.new(prefix: :on)

      def create(attributes)
        emit(:created, attributes)
      end
    end
  end
  let(:target) { target_class.new(uuid: uuid) }

  describe '.initialize' do
    it 'has instance methods of an aggreate' do
      described_class::InstanceMethods.public_instance_methods.each do |meth|
        expect(target_class.new).to respond_to(meth)
      end
    end

    it 'has class methods of an aggreate' do
      described_class::ClassMethods.public_instance_methods.each do |meth|
        expect(target_class).to respond_to(meth)
      end
    end
  end

  describe '#emit(name, args)' do
    after { target.create(attributes) }

    before do
      expect(Jouba.Event).to receive(:new)
        .with(key: target.to_key, name: name, data: attributes).and_return(event)
      expect(target).to receive(:"on_#{name}").with(attributes)
    end

    it 'apply the event' do
      expect(target).to receive(:apply_event).with(event).and_call_original
    end

    it 'refresh the cache' do
      expect(Jouba.Cache).to receive(:refresh).with(target.to_key, target)
        .and_yield.and_call_original
    end

    it 'publish an event' do
      target.subscribe(listener, prefix: :on)
      expect(listener).to receive(:"on_#{name}").with(attributes)
    end
  end

  describe '#to_key' do
    let(:uuid) { 123 }
    it 'delegates to the class method' do
      expect(target_class).to receive(:key_from_uuid).with(target.uuid)
      target.to_key
    end
  end

  describe '#replay(event)' do
    after { target.replay(event) }
    it 'calls the callback_method with the right params' do
      expect(target).to receive(:"on_#{name}").with(attributes)
    end
  end

  describe '.replay(events)' do
    let(:events) { [event, event] }

    after { target_class.replay(events) }
    before { expect(target_class).to receive(:new).and_return(target) }

    it 'create a new instance of the aggregate and apply all the events' do
      expect(target).to receive(:replay).with(event).exactly(2).times
    end
  end

  describe '.find(uuid)' do
    let(:key) { target_class.key_from_uuid(uuid) }
    let(:stream) { [] }
    after { target_class.find(uuid) }

    it 'goes through the cache' do
      expect(target_class).to receive(:stream).with(uuid).and_return(stream)
      expect(target_class).to receive(:replay).with(stream)
      expect(Jouba.Cache).to receive(:fetch).with(key).and_yield.and_call_original
    end
  end

  describe '.stream(uuid)' do
    let(:key) { target_class.key_from_uuid(uuid) }
    let(:params) { {} }
    after { target_class.stream(uuid, params) }
    it 'returns the stream from the EventStore' do
      expect(Jouba.Event).to receive(:stream).with(key, params)
    end
  end

  describe '.key_from_uuid(uuid)' do
    after { target_class.key_from_uuid(uuid) }

    it 'delegates to the configured key structure' do
      expect(Jouba.Key).to receive(:serialize).with(target_class.name, uuid)
    end
  end
end
