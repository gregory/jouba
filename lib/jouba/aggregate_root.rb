module Jouba
  module AggregateRoot
    EVENTS = {
      invalid: :invalid,
      saved: :saved
    }
    def self.included(klass)
      klass.send :include, Entity
      klass.extend ClassMethods
    end

    module ClassMethods
      def publishable_events
        EVENTS.merge(local_publishable_events)
      end

      def local_publishable_events
        {}
      end
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
      if valid?
        publish_raised_events
        publish(self.class.publishable_events[:saved], options) && persist_raised_events
        clear_raised_events
      else
        publish(self.class.publishable_events[:invalid], errors)
      end
      self
    end

    def create(params)
      raise_event :on_create, {aggregate_id: aggregate_id}.merge(params)
    end

    def storage
      Jouba.storage_engine
    end

    private

    def apply_event(event)
      method(:"#{event.to_s}").call(*event.data)
    end

    def contain_raised_event(raised_event)
      raised_events.push  raised_event
    end

    def persist_raised_events
      storage.save(self, raised_events)
    end

    def publish_raised_event(raised_event)
      method(:publish).call(raised_event.name, *raised_event.data)
    end
  end
end
