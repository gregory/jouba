module Jouba
  module Extensions
    module Data
      module Snapshot
        def self.find_snapshot_with_criteria(criteria)
          raise NotImplementedError
        end

        def self.find_or_initialize_by(criteria)
          raise NotImplementedError
        end

        def self.create(params)
          raise NotImplementedError
        end
      end
    end
  end
end
