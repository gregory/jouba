module Jouba
  module Data
    module Mongoid
      class Snapshot
        MAX_VERSIONS = 5
        include Mongoid::Document
        include Mongoid::Timestamps
        include Mongoid::Versioning

        store_in collection: 'snapshots'

        max_versions MAX_VERSIONS

        field :at, as: :aggregate_type, type: String
        field :aid, as: :aggregate_id, type: String
        field :s, as: :snapshot, type: Hash
        field :i, as: :event_seq_num, type: Moped::BSON::ObjectId

        validates :event_seq_num, :aggregate_id, :aggregate_type, :snapshot, presence: true

        def self.find_snapshot_with_criteria(criteria)
          self.order_by(:event_seq_num => :asc).where(criteria).limit(1).last
        end

        def self.find_or_initialize_by(criteria)
          self.find_or_initialize_by(criteria)
        end

        def self.create(params)
          self.create(params)
        end
      end
    end
  end
end
