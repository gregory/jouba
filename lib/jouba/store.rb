require 'yaml'
require 'forwardable'

module Jouba
  class MemoryStore
    attr_reader :db

    def initialize
      flush
    end

    def get(key, _ = {})
      db[key].nil? ? nil : deserialize(db[key])
    end

    def set(key, value)
      db[key] = serialize(value)
    end

    def delete(key)
      db.delete(key)
    end

    def flush
      @db = {}
    end

    def persist(file_path)
      File.open(file_path, 'w') { |file| file.write @db.to_yaml }
    end

    def self.load(file_path)
      new.tap { |store| store.instance_variable_set('@db', YAML.load_file(file_path)) }
    end

    protected

    def deserialize(data)
      YAML.load(data)
    end

    def serialize(data)
      YAML.dump(data)
    end
  end

  class EventStore < MemoryStore
    class Collection
      extend Forwardable
      include Enumerable

      attr_reader :collection
      def_delegators :collection, :each

      def initialize(collection)
        @collection = collection
      end

      def since(time)
        Collection.new collection.select { |item| item.timestamp <= time }
      end
    end

    def get(key, _ = {})
      Collection.new db[key].map { |item| deserialize(item) }
    end

    def set(key, value)
      db[key].push serialize(value)
    end

    def flush
      @db = Hash.new { |h, k| h[k] = [] }
    end
  end
end
