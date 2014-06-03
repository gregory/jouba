module Jouba
  module Data
    module Mongoid
      class Event
        include Mongoid::Document
        include Mongoid::Timestamps

        store_in collection: 'events'

        field :at, as: :aggregate_type, type: String
        field :aid, as: :aggregate_id, type: String
        field :n, as: :name, type: String
        field :d, as: :data, type: Hash
        field :i, as: :seq_num, type: Moped::BSON::ObjectId, default: ->{ Moped::BSON::ObjectId.new }

        scope :for_aggregate, ->(aid){ where(aggregate_id: aid) }
        scope :after_seq_num, ->(seq_num){ where(:seq_num.gt => seq_num) }

        def self.find_events_with_criteria(criteria)
          self.order_by(:seq_num => :asc).where(criteria).to_a
        end
      end
    end
  end
end
