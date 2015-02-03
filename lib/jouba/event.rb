module Jouba
  class Event < Hashie::Trash
    property :key,       required: true
    property :name,      required: true
    property :data,      required: true
    property :uuid, default: ->(e) { e.send(:raw_uuid).to_s }
    property :version, default: ->(e) { e.send(:raw_uuid).version }
    property :timestamp, default: ->(e) { e.send(:raw_uuid).timestamp }

    def self.serialize(event)
      event.to_h
    end

    def self.deserialize(serialized_event)
      new(serialized_event)
    end

    def self.stream(key, params)
      Jouba.Store.get(key, params).map { |event| Event.deserialize(event) }
    end

    def track
      Jouba.Store.set(key, Event.serialize(self))
    end
    alias_method :save, :track

    private

    def raw_uuid
      @raw_uuid ||= self[:uuid].nil? ? UUID.new : UUID.new(self[:uuid])
    end
  end
end
