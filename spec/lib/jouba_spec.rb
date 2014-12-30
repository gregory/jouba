require 'spec_helper'

describe Jouba do
  describe '.config' do
    subject { described_class.config }

    it { should be_a Jouba::Configuration }

    it 'has a store reader' do
      expect(subject.store).to be_a Hashie::Mash
    end
  end

  describe '.connection' do
    let(:store_adapter) { Class }

    subject { described_class.store }

    before do
      Jouba.register_adapter(:sql, store_adapter)
    end

    after do
      Jouba.adapter = :random
    end

    context 'when adapter has been registered' do
      before do
        Jouba.adapter = :sql
      end

      it 'return a new instance' do
        expect(subject).to be_a(store_adapter)
      end

      it 'return the same instance' do
        expect(subject.object_id).to eq Jouba.store.object_id
      end

      context 'when unknown adapter' do
        before do
          Jouba.adapter = :foo
        end

        it 'raise an error' do
          expect { subject }.to raise_error
        end
      end
    end
  end

  describe '.commit(aggregate, event)' do
    let(:aggregate) { double(:aggregate) }
    let(:event) { double(:event) }

    it 'commit the event to the store' do
      expect(described_class.store).to receive(:append_events).with(aggregate, event)
      described_class.commit(aggregate, event)
    end
  end

  describe '.find(aggreate_class, aggregate_id)' do
    let(:aggregate_id) { 'id' }
    let(:aggregate_class) { 'aggregate_class' }
    let(:aggregate) { double(:aggregate) }

    it 'retrieve an aggregate from the store' do
      expect(described_class.store).to receive(:find).with(aggregate_class, aggregate_id).and_return(aggregate)
      expect(described_class.find(aggregate_class, aggregate_id)).to eq aggregate
    end
  end
end
