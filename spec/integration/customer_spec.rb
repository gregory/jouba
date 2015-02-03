require 'spec_helper'
require 'jouba/aggregate'

describe 'Aggregate' do
  class Customer < Hashie::Dash
    include Jouba::Aggregate.new(prefix: :on)
    property :uuid
    property :name

    def self.create(attributes)
      Customer.new(uuid: SecureRandom.uuid).tap do |customer|
        customer.create(attributes.merge(uuid: customer.uuid))
      end
    end

    def create(attributes)
      emit(:created, attributes)
    end

    private

    def on_created(attributes)
      update_attributes!(attributes)
    end
  end

  let(:name) { 'foo' }

  describe 'create new customer' do
    subject { Customer.create(name: name) }

    it 'creates a customer' do
      expect(subject).to be_a Customer
      expect(subject.name).to eq name
    end

    it 'increased the stream stack' do
      expect(Customer.stream(subject.uuid).size).to eq 1
    end

    it 'it findable' do
      expect(Customer.find(subject.uuid)).to eq subject
    end

    describe 'with cache' do
      before do
        Jouba.config.Cache = Jouba::Cache::Memory.new
      end

      after do
        Jouba.config.Cache = Jouba::Cache::Null.new
      end

      context 'when there is something in the cache' do
        before { Customer.create(name: name) }
        after { 10.times { Customer.find(subject.uuid) } }

        it 'dont uses the cache' do
          expect(Customer).not_to receive(:replay)
        end
      end

      context 'when there is nothing in the cache' do
        let(:customer) { Customer.create(name: name) }
        let(:key) { Customer.key_from_uuid(customer.uuid) }
        let(:uuid) { customer.uuid }

        before do
          expect(Jouba.Cache.get(key)).not_to eq nil
          Jouba.Cache.store.flush
          expect(Jouba.Cache.get(key)).to eq nil
        end

        after { 10.times { Customer.find(uuid) } }

        it 'uses the cache once' do
          expect { |b| Jouba.Cache.fetch(key, &b) }.to yield_control.exactly(1)
          expect(Jouba.Cache).to receive(:fetch).exactly(10)
        end
      end
    end
  end
end
