module Jouba
  module Data
    def to_model
      params = {aggregate_id: self.aggregate_id}
      self.aggregate_type.constantize.new(params)
    end

    def to_hash
      raise NotImplementedError
    end
  end
end
