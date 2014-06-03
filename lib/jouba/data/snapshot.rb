module Jouba
  module Data
    class Snapshot
      def events
        ::Es::EventDocument.for_aggregate(self.aggregate_id)
      end

      def last_events
        events.after_seq_num(self.event_seq_num).to_a
      end

      def to_model
        params = self.snapshot.merge({aggregate_id: self.aggregate_id})
        self.aggregate_type.constantize.new(ActiveSupport::HashWithIndifferentAccess.new(params))
      end
    end
  end
end
