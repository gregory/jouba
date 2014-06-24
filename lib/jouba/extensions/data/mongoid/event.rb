module Jouba
  module Extensions
    module Data
      module Event
        module Mongoid
          def self.included(klass)
            klass.send :include, ::Mongoid::Document
            klass.send :include, ::Mongoid::Timestamps
            klass.store_in collection: 'events'

            klass.field :at, as: :aggregate_type, type: String
            klass.field :aid, as: :aggregate_id, type: String
            klass.field :n, as: :name, type: String
            klass.field :d, as: :data, type: Array
            klass.field :i, as: :seq_num, type: ::BSON::ObjectId, default: ->{ ::BSON::ObjectId.new } #Need to be handled by rquest store => http://brandur.org/antipatterns

            klass.scope :for_aggregate, ->(aid){ where(aggregate_id: aid) }
            klass.scope :after_seq_num, ->(seq_num){ where(:seq_num.gt => seq_num) }

            klass.extend ClassMethods
          end

          module ClassMethods
            def find_events_with_criteria(criteria)
              order_by(:seq_num => :asc).where(criteria).to_a
            end
          end
        end
      end
    end
  end
end
