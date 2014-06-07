require 'store'

describe Jouba::Store do

  subject{ described_class }

  describe '.find(criteria)' do
    subject{ described_class.find(criteria) }
    let(:events){ [ double(:event1), double(:event2) ] }
    let(:aggregate){ double(:aggregate) }

    before do
      described_class.should_receive(:rebuild_aggregate).with(aggregate, events)
    end
    context 'when criteria is a hash' do
      let(:criteria){ { foo: 'bar' } }

      it 'find and rebuild the aggregate' do
        described_class.should_receive(:find_events_with_criteria).with(criteria).and_return([events, aggregate])
        subject.find(criteria)
      end
    end

    context 'when criteria is a string' do
      let(:criteria){ 'bar' }

      it 'find and rebuild the aggregate' do
        described_class.should_receive(:find_events_with_criteria).with({ aggregate_id: criteria }).and_return([events, aggregate])
        subject.find(criteria)
      end
    end
  end

  describe '.find_events_and_aggregate_with_criteria(criteria)' do
    subject{ described_class.find_events_and_aggregate_with_criteria(criteria) }
    let(:criteria){ { foo: bar } }

    before do
      described_class.should_receive(:find_snapshot_with_criteria).with(criteria).and_return(snapshot)
    end

    context 'when snapshot is not nil' do
      let(:snapshot){ double(:snapshot) }
      let(:last_events){ [double(:event)] }
      let(:model){ double(:model) }

      before do
        snapshot.should_receive(:last_events).and_return(event)
        snapshot.should_receive(:to_model).and_return(model)
      end

      it 'returns the last event and the model' do
        subject.should_eq [last_events, model]
      end
    end

    context 'when snapshot is nil' do
      let(:snapshot){ nil }
      let(:model){ double(:model) }

      before do
        described_class.should_receive(:find_events_and_aggregate_with_criteria).with(criteria).and_return(events)
      end

      context 'when events is empty' do
        let(:events){ [] }
        it 'raise an exception' do
          expect{subject}.to raise_exception{ Jouba::Exception::NotFound }
        end
      end

      context 'wen events are present' do
        let(:event){ double(:event, model: model) }
        let(:events){ [event] }

        before do
          event.should_receive(:to_model).and_return(model)
        end

        it 'return the last event and his model' do
          subject.should eq [events, model]
        end
      end
    end
  end

  describe '.rebuild_aggregate(aggregate, events)' do
    #integ
  end


  describe '.find_events_with_criteria(criteria)' do
    #integ
  end

  describe '.find_snapshot_with_criteria(criteria)' do
    #integ
  end


  describe '.rebuild_aggregate(aggregate, events)' do
    #integration test
  end

  describe '.documents_to_events(documents)' do
    #integration
  end
end
