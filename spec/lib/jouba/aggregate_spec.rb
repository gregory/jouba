require 'ostruct'
require 'spec_helper'

describe Jouba::Aggregate do
  let(:aggregate_class) do
    Class.new do
      include Jouba::Aggregate
    end
  end

  subject { aggregate_class }

  describe '.find(id)' do
    let(:id) { 2 }

    it 'query the store' do
      expect(Jouba).to receive(:find).with(aggregate_class, id)
      subject.find(id)
    end
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
