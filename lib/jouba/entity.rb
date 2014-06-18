module Jouba
  module Entity
    def self.included(klass)
      klass.send :include, ActiveModel::Validations
      klass.send :include, Wisper::Publisher
      klass.extend ClassMethods
    end

    def after_initialize; end

    module ClassMethods
      def generate_aggregate_id
        SecureRandom.uuid
      end

      def generate_aggregate_type
        self.name
      end
    end
  end
end
