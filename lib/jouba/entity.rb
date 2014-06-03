module Es
  module Entity
    def self.included(klass)
      klass.send :include, Virtus.model
      #klass.send :include, ActiveModel::Serialization
      klass.send :include, Wisper::Publisher
      original_initialize = klass.instance_method(:initialize)
      klass.send :define_method, :initialize do |*args, &block|
        original_initialize.bind(self).call(*args, &block)
        after_initialize
      end
    end

    def after_initialize; end
  end
end
