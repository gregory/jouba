module Jouba
  module Aggregate
    attr_reader :uuid

    include Wisper::Publisher

    def self.included(target_class)
      target_class.extend ClassMethods
    end

    module ClassMethods
      def find(id)
        Jouba.find(self, id)
      end

      def build_from_events(uuid, events)
        new { |aggregate| aggregate[:uuid] = uuid }.apply_events(events)
      end
    end

    def uuid
      @uuid ||= SecureRandom.uuid
    end

    def commit(event_name, args)
      event = Event.build(event_name, args)

      apply_events(event)
      Jouba.commit(self, event)
      publish(event_name, args)
    end

    def apply_events(events)
      [events].flatten.each do |event|
        next unless respond_to?(event.name.to_sym)

        send(event.name.to_sym, event.data)
      end
    end
  end
end
