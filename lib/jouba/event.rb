require 'active_support/hash_with_indifferent_access'
module Jouba
  class Event < ::Hashie::Dash
    property :name, required: true
    property :aggregate_type
    property :aggregate_id
    property :data, type: Hash

    def to_s
      self.name
    end

    def to_hash
      ActiveSupport::HashWithIndifferentAccess.new({
        name: self.name,
        aggregate_type: self.aggregate_type,
        aggregate_id:   self.aggregate_id,
        data:           JSON.parse(self.data.to_json)
      })
    end
  end
end
