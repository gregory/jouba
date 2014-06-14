require 'spec_helper'

describe Jouba::Store do

  subject{ described_class }

  describe '.find(criteria)' do
    let(:events){ [ double(:event1), double(:event2) ] }
    let(:aggregate){ double(:aggregate) }

    before do
      expect(subject).to receive(:rebuild_aggregate).with(aggregate, events)
    end

    context 'when criteria is a hash' do
      let(:criteria){ { foo: 'bar' } }

      it 'find and rebuild the aggregate' do
        expect(subject).to receive(:find_events_and_aggregate_with_criteria).with(criteria).and_return([events, aggregate])
        subject.find(criteria)
      end
    end

    context 'when criteria is a string' do
      let(:criteria){ 'bar' }

      it 'find and rebuild the aggregate' do
        expect(subject).to receive(:find_events_and_aggregate_with_criteria).with({ aggregate_id: criteria }).and_return([events, aggregate])
        subject.find(criteria)
      end
    end
  end

  describe '.find_events_and_aggregate_with_criteria(criteria)' do
    #subject{ described_class.find_events_and_aggregate_with_criteria(criteria) }
    let(:criteria){ { foo: 'bar' } }

    before do
      expect(subject).to receive(:find_snapshot_with_criteria).with(criteria).and_return(snapshot)
    end

    context 'when snapshot is not nil' do
      let(:snapshot){ double(:snapshot) }
      let(:last_events){ [double(:event)] }
      let(:model){ double(:model) }

      before do
        expect(snapshot).to receive(:last_events).and_return(last_events)
        expect(snapshot).to receive(:to_model).and_return(model)
      end

      it 'returns the last event and the model' do
        expect(subject.find_events_and_aggregate_with_criteria(criteria)).to eq [last_events, model]
      end
    end

    context 'when snapshot is nil' do
      let(:snapshot){ nil }
      let(:model){ double(:model) }

      before do
        allow(subject).to receive(:find_events_with_criteria).with(criteria){ events }
      end

      context 'when events is empty' do
        let(:events){ [] }
        it 'raise an exception' do
          expect{subject.find_events_and_aggregate_with_criteria(criteria)}.to raise_exception{ Jouba::Exceptions::NotFound }
        end
      end

      context 'wen events are present' do
        let(:event){ double(:event, model: model) }
        let(:events){ [event] }

        before do
          expect(event).to receive(:to_model).and_return(model)
        end

        it 'return the last event and his model' do
          expect(subject.find_events_and_aggregate_with_criteria(criteria)).to eq [events, model]
        end
      end
    end
  end

  describe '.rebuild_aggregate(aggregate, events)' do
  end


  describe '.find_events_with_criteria(criteria)' do
    let(:criteria){ { foo: 'bqr' } }
    let(:event_store){ double(:event_store) }

    before{ allow(described_class).to receive(:event_store).and_return( event_store) }
    it 'return the events related to criteria' do
      expect(event_store).to receive(:find_events_with_criteria).with(criteria)
      described_class.find_events_with_criteria(criteria)
    end
  end

  describe '.find_snapshot_with_criteria(criteria)' do
    let(:criteria){ { foo: 'bqr' } }
    let(:snapshot_store){ double(:snapshot_store) }

    before{ allow(subject).to receive(:snapshot_store).and_return( snapshot_store) }
    it 'return the snapshot related to criteria' do
      expect(snapshot_store).to receive(:find_snapshot_with_criteria).with(criteria)
      subject.find_snapshot_with_criteria(criteria)
    end
  end

  describe '.rebuild_aggregate(aggregate, events)' do
    #integration test
  end

  describe '.documents_to_events(documents)' do
  end

  describe '.events_to_hash(events)' do
    let(:events) do
      [
        double(:doc1, name: "name1", data: { foo: 'bar1' }),
        double(:doc2, name: "name2", data: { foo: 'bar2' })
      ]
    end
    let(:hash_of_events) do
      [
        { "name" => "name1", "data" => { foo: 'bar1' } },
        { "name" => "name2", "data" => { foo: 'bar2' } }
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
