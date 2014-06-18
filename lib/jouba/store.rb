module Jouba
  class Store
    def self.find(criteria)
      criteria = criteria.is_a?(String) ? { aggregate_id: criteria } : criteria

      events, aggregate = find_events_and_aggregate_with_criteria(criteria)

      rebuild_aggregate(aggregate, events)
    end

    def self.find_snapshot_with_criteria(criteria)
      snapshot_store.find_snapshot_with_criteria(criteria)
    end

    def self.find_events_with_criteria(criteria)
      event_store.find_events_with_criteria(criteria)
    end

    def self.find_events_and_aggregate_with_criteria(criteria)
      snapshot = find_snapshot_with_criteria(criteria)

      if snapshot.nil?
        events = find_events_with_criteria(criteria)
        fail(Exceptions::NotFound, 'Events not found') unless events.present?
        [events, events.last.to_model]
      else
        [snapshot.last_events, snapshot.to_model]
      end
    end

    def self.rebuild_aggregate(aggregate, events)
      return rebuild_aggregate(aggregate, [events]) unless events.is_a? Array

      e = documents_to_events(events)
      aggregate.replay_events(e)
      take_snapshot(aggregate, events.last) if events.size > Store.snapshot_if_build_x_events
      aggregate
    end

    def self.take_snapshot(aggregate, last_event)
      aggregate_snapshot = JSON.parse aggregate.to_json # NOTE: Hack to get all the object's properties
      aggregate_id = aggregate_snapshot.delete('aggregate_id')
      snapshot = snapshot_store.find_or_initialize_by(aggregate_id: aggregate_id)

      snapshot.aggregate_type = last_event.aggregate_type
      snapshot.event_seq_num  = last_event.seq_num
      snapshot.snapshot       = aggregate_snapshot
      snapshot.save
    end

    def self.documents_to_events(documents)
      return documents_to_events([documents]) unless documents.is_a? Array
      documents.map { |doc| event_from_document(doc) }
    end

    def self.event_from_document(doc)
      Event.new doc.to_hash
    end

    def self.events_to_hash(events)
      return events_to_hash([events]) unless events.is_a? Array

      events.map { |event| { name: event.name, data: event.data } }
    end

    def save(aggregate, raised_events)
      last_raised_event = raised_events.map { |event| create_event(event) }.last
      Store.take_snapshot(aggregate, last_raised_event) if raised_events.size > Store.snapshot_if_save_x_events
      aggregate
    end

    private

    def self.snapshot_if_save_x_events
      Jouba.config.snapshot_if_save_x_events
    end

    def self.snapshot_if_build_x_events
      Jouba.config.snapshot_if_build_x_events
    end

    def self.event_store
      Jouba.event_store
    end

    def self.snapshot_store
      Jouba.snapshot_store
    end

    def create_event(event)
      Store.event_store.create(event)
    end
  end
end
