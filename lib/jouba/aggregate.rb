require 'jouba'
require 'jouba/cache'

module Jouba
  class Aggregate < Module
    attr_reader :options

    def initialize(options = {})
      @options = options
      tap do |mod|
        mod.define_singleton_method :included do |object|
          super(object)
          after_included(object, mod)
        end
      end
    end

    def after_included(object, mod)
      object.extend(ClassMethods)
      object.send :include, InstanceMethods
      object.send :include, Wisper::Publisher
      object.define_singleton_method :__module_options__ do
        mod.options
      end
    end

    module InstanceMethods
      def emit(name, *args)
        Jouba.emit(to_key, name, args) do |event|
          apply_event(event)
          Jouba.Cache.refresh(to_key, self) { event.track }
          publish(event.name, event.data)
        end
      end

      def replay(event)
        send __callback_method__(:"#{event.name}"), *event.data
      end
      alias_method :apply_event, :replay

      def to_key
        fail 'Please make sure there is a uuid first' unless respond_to?(:uuid) && !uuid.nil?
        self.class.key_from_uuid(uuid)
      end

      private

      def __callback_method__(name)
        :"#{__callback_prefix__}#{name}"
      end

      def __callback_prefix__
        options = self.class.__module_options__
        options[:prefix].nil? ? '' : "#{options[:prefix]}_"
      end
    end

    module ClassMethods
      def replay(events)
        new.tap { |aggregate| Array(events).each { |event| aggregate.replay(event) } }
      end

      def find(uuid)
        key = key_from_uuid(uuid)
        Jouba.Cache.fetch(key) { replay stream(uuid) }
      end

      def stream(uuid, params = {})
        Jouba.Event.stream(key_from_uuid(uuid), params)
      end

      def key_from_uuid(uuid)
        Jouba.Key.serialize(name, uuid) # => default "ClassName.id"
      end
    end
  end
end
