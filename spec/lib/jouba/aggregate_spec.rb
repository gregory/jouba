require 'ostruct'
require 'spec_helper'

describe Jouba::Aggregate do
  let(:aggregate_class) { Class.new { include Jouba::Aggregate } }

  subject { aggregate_class }

  describe '.find(id)' do
    let(:id) { 2 }

    it 'query the store' do
      expect(Jouba).to receive(:find).with(aggregate_class, id)
      subject.find(id)
    end
  end

  describe '.build_from_events(uuid, events)' do
    let(:aggregate) { aggregate_class.new }
    let(:uuid) { '123' }
    let(:events) { [double(:event)] }

    it 'build the aggregate by applying the events' do
      expect(aggregate_class).to receive(:new).and_return(aggregate)
      expect(aggregate).to receive(:[]=).with(:uuid, uuid)
      expect(aggregate).to receive(:apply_events).with(events)
      aggregate_class.build_from_events(uuid, events)
    end

    context 'when after_initialize_blocks is not empty' do
      let(:observer) { double(:observer) }

      before do
        aggregate_class.after_initialize do |aggregate|
          aggregate.subscribe(observer)
        end
      end

      it 'apply the blocks once initialized' do
        expect(aggregate_class).to receive(:new).and_return(aggregate)
        expect(aggregate).to receive(:apply_events).with(events)
        expect(aggregate).to receive(:[]=).with(:uuid, uuid)
        expect(aggregate).to receive(:subscribe).with(observer)
        aggregate_class.build_from_events(uuid, events)
      end
    end

  end

  describe '.after_initialize(&block)' do
  end

  describe '#uuid' do
    let(:uuids) { (1..3).map { aggregate_class.new.uuid } }

    it 'return a different uuid for each instance' do
      expect(uuids.uniq.size).to eq 3
    end
  end

  describe '#commit(aggregate, event)' do
    let(:aggregate) { aggregate_class.new }
    let(:data) { { value: 10, meta: OpenStruct.new(foo: 'bar') } }
    let(:event_name) { 'add_credit' }
    let(:event) { Jouba::Event.new(name: event_name, data: data) }

    it 'append the event to the store' do
      expect(Jouba.store).to receive(:append_events).with(aggregate, event)
      expect(Jouba::Event).to receive(:build).with(event_name, data).and_return(event)
      expect(aggregate).to receive(event_name).with(data)
      aggregate.commit(event_name, data)
    end
  end
end
