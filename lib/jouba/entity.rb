module Jouba
  module Entity
    def self.included(klass)
      Jouba::Extensions::Hashie::Entity.tap do |extension|
        klass.send(:include, extension) if klass <= Hashie::Dash && !klass.singleton_class.included_modules.include?(extension)
      end
      klass.send :include, ActiveModel::Validations
      klass.send :include, Wisper::Publisher
      klass.extend ClassMethods

      original_initialize = klass.instance_method(:initialize)
      klass.send :define_method, :initialize do |*args, &block|
        original_initialize.bind(self).call(*args, &block)
        after_initialize
        Jouba.config.default_listeners.each { |listener| self.subscribe(listener) }
      end
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
