require 'spec_helper'

describe Jouba do
  describe '.config' do
    subject { described_class.config }

    it { should be_a Hashie::Mash }

    it 'has a stores reader' do
      expect(subject.stores).to be_a Hashie::Mash
    end

    context 'when we try to access an unknown key' do
      let(:unkwown_key) { :foo }

      it 'fails' do
        expect { subject[unkwown_key] }.to raise_error
      end
    end
  end

  describe '.adapters_map' do
    subject { described_class.adapters_map }
    let(:existing_adapter) { :sql }
    let(:unknown_adapter) { :foo }

    before do
      Jouba.register_adapter(existing_adapter, Class)
    end

    after do
      Jouba.adapters_map.delete(existing_adapter)
    end

    it 'fail when we try to access an unknown adapter' do
      expect { subject[existing_adapter] }.not_to raise_error
      expect { subject[unknown_adapter] }.to raise_error
    end
  end

  describe 'register_adapter(key, class)' do
    let(:key) { :adapter }
    let(:adapter_class) { double(:adapter_class) }

    before do
      expect { Jouba.adapters_map[key] }.to raise_error
      Jouba.register_adapter(key, Class)
    end

    after do
      Jouba.adapters_map.delete(key)
    end

    it 'assign the class to the key in the adapters_map' do
      expect { Jouba.adapters_map[key] }.not_to raise_error
    end
  end

  describe 'register_store(name)' do
    let(:store_name) { :foo }
    let(:adapter_name) { :sql }
    let(:adapter_class) { double(:adapter_class) }
    let(:adapter_instance) { double(:adapter_instance) }
    let(:config_h) { double(:config_h) }

    before do
      Jouba.register_adapter(adapter_name, adapter_class)
      expect { Jouba.stores[store_name] }.to raise_error

      expect(described_class.config.stores).to receive(:[]).with(store_name).and_return(config_h)
      config_h.stub(:adapter).and_return(adapter_name)
      expect(adapter_class).to receive(:new).with(config_h).and_return(adapter_instance)
      Jouba.register_store(store_name) do |c|
        c.adapter = adapter_name
      end
    end

    after do
      Jouba.stores.delete(store_name)
      Jouba.adapters_map.delete(adapter_name)
    end

    subject { described_class.stores[store_name] }

    it 'sets the store in the Jouba.stores' do
      expect(subject).to eq adapter_instance
    end
  end

  describe '.stores' do
    subject { described_class.stores }
    let(:existing_store) { :existing }
    let(:unknown_store) { :foo }

    before do
      Jouba.register_store(existing_store) do |config|
        config.adapter = :random # Check spec_helper
      end
    end

    after do
      Jouba.stores.delete(existing_store)
    end

    it 'fail when we try to access an unknown adapter' do
      expect { subject[existing_store] }.not_to raise_error
      expect { subject[unknown_store] }.to raise_error
    end

    it 'returns the same instance' do
      expect(subject[existing_store].object_id).to eq Jouba.stores[existing_store].object_id
    end
  end

  describe '.commit(aggregate, event)' do
    let(:aggregate) { double(:aggregate) }
    let(:event) { double(:event) }

    it 'commit the event to the store' do
      expect(described_class.stores[:events]).to receive(:append_events).with(aggregate, event).and_return(true)
      expect { |b| described_class.commit(aggregate, event, &b) }.to yield_with_no_args
    end

    context 'when store hasnt been able to append the events' do
      before do
        expect(described_class.stores[:events]).to receive(:append_events).with(aggregate, event).and_return(false)
      end

      it 'doesnt yield' do
        expect { |b| described_class.commit(aggregate, event, &b) }.not_to yield_with_no_args
      end
    end
  end

  describe '.find(aggreate_class, aggregate_id)' do
    let(:aggregate_id) { 'id' }
    let(:aggregate_class) { 'aggregate_class' }
    let(:aggregate) { double(:aggregate) }

    it 'retrieve an aggregate from the store' do
      expect(described_class.stores[:events]).to receive(:find)
        .with(aggregate_class, aggregate_id).and_return(aggregate)
      expect(described_class.find(aggregate_class, aggregate_id)).to eq aggregate
    end
  end

  describe '.alias_store(alias_name, target)' do
    let(:alias_name) { :alias_name }
    let(:target) { :target }

    before do
      Jouba.register_store(target) do |config|
        config.adapter = :random # Check spec_helper
      end
    end

    after do
      Jouba.stores.delete(target)
      Jouba.stores.delete(alias_name)
    end

    it 'alias the two stores' do
      expect { Jouba.stores[alias_name] }.to raise_error
      Jouba.alias_store(alias_name, target)
      expect { Jouba.stores[alias_name] }.not_to raise_error
      expect(Jouba.stores[alias_name].object_id).to eq Jouba.stores[target].object_id

    end
  end

  describe '.locked?(key)' do
    let(:key) { 'key' }
    it 'asks the lock store if a key is locked' do
      expect(Jouba.stores[:lock]).to receive(:locked?).with(key)
      described_class.locked?(key)
    end
  end

  describe '.with_lock(key)' do
    let(:key) { 'key' }

    context 'when the key is not locked' do
      before do
        expect(Jouba.stores[:lock]).to receive(:lock!).with(key)
        expect(Jouba.stores[:lock]).to receive(:unlock!).with(key)
        expect(Jouba).to receive(:locked?).with(key).and_return(false)
      end

      it 'yield with lock' do
        expect { |b| described_class.with_lock(key, &b) }.to yield_with_no_args
      end

      context 'when yield fails' do
        let(:exception) { StandardError.new }

        it 'make sure to release the lock' do
          expect { |b| described_class.with_lock(key){ fail(exception) } }.to raise_error
        end
      end
    end

    context 'when the key is locked' do
      before do
        expect(Jouba).to receive(:locked?).with(key).and_return(true)
        expect(Jouba.stores[:lock]).not_to receive(:unlock!).with(key)
      end

      it 'fails with a LockException' do
        expect { |b| described_class.with_lock(key, &b) }.to raise_error(Jouba::LockException)
      end
    end
  end
end
