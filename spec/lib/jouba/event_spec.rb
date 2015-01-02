require 'spec_helper'

describe Jouba::Event do
  let(:event_name) { 'event_name' }
  let(:data) { [:foo, 1, 'bar', { foo: 'bar'}, [1,2] ] }
  let(:occured_at) { double(:time) }

  describe '.build(event_name, data)' do
    before do
      Time.stub_chain(:now, :utc).and_return(occured_at)
    end

    subject { described_class.build(event_name, data) }

    it 'build an event' do
      expect(subject.name).to eq event_name
      expect(subject.data).to eq data
      expect(subject.occured_at).to eq occured_at
    end
  end
end
