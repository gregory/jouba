module Jouba
  module Extensions
    module Data
      module Event
        def self.after_seq_num(seq_num)
          raise NotImplementedError
        end

        def self.for_aggregate(aggregate_id)
          raise NotImplementedError
        end

        def self.find_events_with_criteria(criteria)
          raise NotImplementedError
        end
      end
    end
  end
end
