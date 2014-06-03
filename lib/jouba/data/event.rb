module Jouba
  module Data
    class Event
      def to_model
        params = {aggregate_id: self.aggregate_id}
        self.aggregate_type.constantize.new(params)
      end

      def to_hash
        {
          name:           self.name,
          aggregate_type: self.aggregate_type,
          aggregate_id:   self.aggregate_id,
          data:           self.data.map{|d| d.is_a?(Hash) ? ActiveSupport::HashWithIndifferentAccess.new(d) : d }
        }
      end
    end
  end
end
