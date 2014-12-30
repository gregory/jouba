module Jouba
  class Event < Hashie::Dash
    include Hashie::Extensions::IndifferentAccess

    property :name, required: true
    property :data, required: true
    property :occured_at, default: -> { Time.now.utc }

    def self.build(event_name, data)
      new(name: event_name, data: data)
    end
  end
end
