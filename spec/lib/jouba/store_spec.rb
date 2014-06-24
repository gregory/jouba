require 'spec_helper'

describe Jouba::Store do

  subject { described_class }

  describe '.find(criteria)' do
    let(:events) { [double(:event1), double(:event2)] }
    let(:aggregate) { double(:aggregate) }

    before do
      expect(subject).to receive(:rebuild_aggregate).with(aggregate, events)
    end

    context 'when criteria is a hash' do
      let(:criteria) { { foo: 'bar' } }

      it 'find and rebuild the aggregate' do
        expect(subject).to receive(:find_events_and_aggregate_with_criteria)
          .with(criteria).and_return([events, aggregate])
        subject.find(criteria)
      end
    end

    context 'when criteria is a string' do
      let(:criteria) { 'bar' }

      it 'find and rebuild the aggregate by setting aggregate_id as criteria' do
        expect(subject).to receive(:find_events_and_aggregate_with_criteria)
          .with(aggregate_id: criteria).and_return([events, aggregate])
        subject.find(criteria)
      end
    end
  end

  describe '.find_events_and_aggregate_with_criteria(criteria)' do
    let(:criteria) { { foo: 'bar' } }

    before do
      expect(subject).to receive(:find_snapshot_with_criteria).with(criteria).and_return(snapshot)
    end

    context 'when snapshot is not nil' do
      let(:last_events) { [double(:event)] }
      let(:model) { double(:model) }
      let(:snapshot) { double(:snapshot, to_model: model, last_events: last_events) }

      it 'returns the last event and the model' do
        expect(subject.find_events_and_aggregate_with_criteria(criteria)).to eq [last_events, model]
      end
    end

    context 'when there is no snapshot' do
      let(:snapshot) { nil }
      let(:model) { double(:model) }

      before do
        expect(subject).to receive(:find_events_with_criteria).with(criteria) { events }
      end

      context 'and no events' do
        let(:events) { [] }
        it 'raise an exception' do
          expect { subject.find_events_and_aggregate_with_criteria(criteria) }
            .to raise_exception { Jouba::Exceptions::NotFound }
        end
      end

      context 'but there is events' do
        let(:event) { double(:event, to_model: model) }
        let(:events) { [event] }

        it 'return the last events and the model' do
          expect(subject.find_events_and_aggregate_with_criteria(criteria)).to eq [events, model]
        end
      end
    end
  end

  describe '.rebuild_aggregate(aggregate, events)' do
    subject { described_class.rebuild_aggregate(aggregate, events) }
    let(:aggregate) { double(:aggregate) }
    let(:events) { double(:events) }

    before do
      expect(described_class).to receive(:documents_to_events).and_return(events)
      expect(aggregate).to receive(:replay_events).with(events).and_return(aggregate)
    end

    it 'build the aggregate' do
      expect(subject).to eq aggregate
    end

    context 'when there is too much events' do
      let(:x){ 5 }
      let(:events){ Array.new(x){ double(:event)} }

      before do
        expect(described_class).to receive(:snapshot_if_build_x_events).and_return(x-1)
      end

      it 'takes a snapshot' do
        expect(described_class).to receive(:take_snapshot).with(aggregate, events.last)
        expect(subject).to eq aggregate
      end
    end
  end

  describe 'take_snapshot(aggregate, last_event)' do
    let(:aggregate_id) { 'bar_id' }
    let(:aggregate_type) { 'foo_type' }
    let(:seq_num) { 'foo_seq_num' }
    let(:aggregate_h) { { foo: 'barbar', bar: { foo: 'bar' } } }
    let(:aggregate) { double(:aggregate, to_hash: aggregate_h) }
    let(:last_event) { double(:last_event, seq_num: seq_num, aggregate_type: aggregate_type) }
    let(:snapshot) { double(:snapshot) }

    subject { described_class.take_snapshot(aggregate, last_event) }

    before do
      allow(aggregate_h).to receive(:delete).with(:aggregate_id).and_return(aggregate_id)
      expect(described_class.snapshot_store).to respond_to(:find_or_initialize_by)
      expect(described_class.snapshot_store).to receive(:find_or_initialize_by).with(aggregate_id: aggregate_id).and_return(snapshot)
    end

    it 'takes a snapshot' do
      expect(snapshot).to receive(:aggregate_type=).with(aggregate_type)
      expect(snapshot).to receive(:event_seq_num=).with(seq_num)
      expect(snapshot).to receive(:snapshot=).with(aggregate_h)
      expect(snapshot).to receive(:save)
      subject
    end
  end

  describe '.find_events_with_criteria(criteria)' do
    # TODO: integration test
  end

  describe '.find_snapshot_with_criteria(criteria)' do
    # TODO: integration test
  end

  describe '.rebuild_aggregate(aggregate, events)'
  describe '.event_from_document(doc)'
  describe '.documents_to_events(documents)'

  describe '.events_to_hash(events)' do
    let(:events) do
      [
        double(:doc1, name: 'name1', data: { foo: 'bar1' }),
        double(:doc2, name: 'name2', data: { foo: 'bar2' })
      ]
    end
    let(:hash_of_events) do
      [
        Jouba::Event.new(name: 'name1', data: { foo: 'bar1' }),
        Jouba::Event.new(name: 'name2', data: { foo: 'bar2' })
      ]
    end

    before do
      events.each_with_index do |e, i|
        expect(e).to receive(:to_hash).and_return(hash_of_events[i])
      end
    end
    it 'return a hash for each event' do
      expect(described_class.documents_to_events(events)).to eq hash_of_events
    end
  end
end
