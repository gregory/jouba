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

      def build_from_events(uuid, events=[])
        new.tap do |aggregate|
          aggregate[:uuid] = uuid
          aggregate.apply_events(events)

          after_initialize_blocks.each do |block|
            block.call(aggregate)
          end
        end
      end

      def after_initialize(&block)
        after_initialize_blocks.push(block)
      end

      private

      def after_initialize_blocks
        @after_initialize_blocks ||= []
      end
    end

    def uuid
      @uuid ||= SecureRandom.uuid
    end

    def commit(event_name, args)
      event = Event.build(event_name, args)

      apply_events(event)
      Jouba.commit(self, event) do
        publish(event_name, args)
      end
    end

    def commit_with_lock(event_name, args, lock_key)
      raise "Locked" if Jouba.locked?(lock_key)
      Jouba.with_lock(lock_key) do
        commit(event_name, args)
      end
    end

    def apply_events(events)
      [events].flatten.each do |event|
        next unless respond_to?(event.name.to_sym)

        send(event.name.to_sym, event.data)
      end
    end
  end
end
