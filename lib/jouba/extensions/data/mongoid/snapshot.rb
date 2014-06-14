module Jouba
  module Extensions
    module Data
      module Snapshot
        module Mongoid
          def self.included(klass)
            klass.send :include, InstanceMethods
            klass.extend ClassMethods
            klass.send :include, ::Mongoid::Document
            klass.send :include, ::Mongoid::Timestamps
            #include ::Mongoid::Versioning

            klass.store_in collection: 'snapshots'

            #max_versions MAX_VERSIONS

            klass.field :at, as: :aggregate_type, type: String
            klass.field :aid, as: :aggregate_id, type: String
            klass.field :s, as: :snapshot, type: Hash
            klass.field :i, as: :event_seq_num, type: ::BSON::ObjectId

            klass.validates :event_seq_num, :aggregate_id, :aggregate_type, :snapshot, presence: true
          end

          module InstanceMethods
            MAX_VERSIONS = 5
          end

          module ClassMethods
            def find_snapshot_with_criteria(criteria)
              order_by(:event_seq_num => :asc).where(criteria).limit(1).last
            end

            def find_or_initialize_by(criteria)
              find_or_initialize_by(criteria)
            end

            def create(params)
              create(params)
            end
          end
        end
      end
    end
  end
end
