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
      include Wisper::Publisher

      def create(attributes)
        emit(:created, attributes)
      end
    end
  end
  let(:target) { target_class.new(uuid: uuid) }
  let(:listener) { double(:listener) }

  describe '#emit(name, data)' do
    after { target.create(attributes) }

    describe '#5 dont splat the emit args' do
      before do
        expect(Jouba).to receive(:emit)
          .with(target.to_key, name, attributes).and_return(event).and_call_original
        target.subscribe(listener)
        expect(target).to receive(:"on_#{name}").with(attributes)
      end

      it 'sends events with non array argument' do
        expect(listener).to receive(:"#{name}").with(attributes)
        expect(listener).not_to receive(:"#{name}").with([attributes])
      end

      context 'when we emit with more than one argument' do
        let(:attributes) { [1, { foo: 'bar' }]  }

        it 'fails whith ArgumentError' do
          expect { target.create(*attributes) }.to raise_error(ArgumentError)
        end
      end
    end
  end
end
