module Jouba
  module AggregateRoot
    def self.included(klass)
      klass.send :include, Entity
    end

    def clear_raised_events
      @raised_events = []
    end

    def raise_event(name, *attributes)
      raised_event = Event.new(name: name, data: attributes)

      apply_event(raised_event)
      raised_event.aggregate_type = self.class.to_s
      raised_event.aggregate_id = self.aggregate_id

      contain_raised_event raised_event
      self
    end

    def publish_raised_events
      raised_events.each{ |raised_event|  publish_raised_event(raised_event) }
    end

    def raised_events
      @raised_events ||= []
    end

    def replay_events(events=[])
      return replay_events([events]) unless events.is_a? Array

      events.each{ |event| apply_event(event) }
    end

    def save(options={})
      publish_raised_events
      publish(:save, options) && persist_raised_events
      clear_raised_events
      self
    end

    def create(params)
      raise_event :on_create, {aggregate_id: self.aggregate_id}.merge(params)
    end

    def update_attributes(params)
      raise_event :on_update_attributes, params
    end

    def storage
      Jouba.storage_engine
    end

    private

    def apply_event(event)
      method(:"#{event.to_s}").call(*event.data)
    end

    def contain_raised_event(raised_event)
      self.raised_events.push  raised_event
    end

    def on_update_attributes(params)
      self.attributes = params
    end
    alias :on_create :on_update_attributes

    def persist_raised_events
      storage.save(self, raised_events)
    end

    def publish_raised_event(raised_event)
      method(:publish).call(raised_event.name, *raised_event.data)
    end
  end
end
