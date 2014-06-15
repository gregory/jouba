require 'ostruct'
module Jouba
  class Configuration
    attr_accessor :event_store, :snapshot_store, :storage_strategy, :storage_engine
    attr_accessor :snapshot_if_save_x_events, :snapshot_if_build_x_events

    def snapshot_if_build_x_events
      @snapshot_if_build_x_events || 5
    end

    def snapshot_if_save_x_events
      @snapshot_if_save_x_events || 5
    end

    def storate_strategy
      @storage_strategy || (raise NotImplementedError.new("Please set a storage_strategy first ex: :mongoid"))
    end

    def event_store=(value)
      value.send :include, Extensions::Data::Event.const_get(strategy_capitalized)
    end

    def event_store
      @event_store ||= Data::Event.send :include, Extensions::Data::Event.const_get(strategy_capitalized)
    end

    def snapshot_store=(value)
      value.send :include, Extensions::Data::Snapshot.const_get(strategy_capitalized)
    end

    def snapshot_store
      @snapshot_store ||= Data::Snapshot.send :include, Extensions::Data::Snapshot.const_get(strategy_capitalized)
    end

    def storage_engine
      @storage_engine ||= Store.new
    end

    private

    def strategy_capitalized
      storage_strategy.to_s.capitalize
    end
  end
end
