require 'forwardable'

module Jouba
  module Cache
    class Null
      def fetch(key);          yield; end
      def refresh(key, value); yield; end
    end

    class Memory
      extend Forwardable

      attr_reader :store

      def_delegators :store, :set, :get, :persist

      def initialize
        @store = MemoryStore.new
      end

      def fetch(key)
        get(key) || yield.tap { |value| store.set(key, value) }
      end

      def refresh(key, value)
        store.set(key, value)
        yield
      end

      def self.load(file_path)
        @store = MemoryStore.load(file_path)
      end
    end
  end
end
