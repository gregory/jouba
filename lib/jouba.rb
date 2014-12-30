require 'hashie'
require 'wisper'

require 'jouba/version'
require 'jouba/event'
require 'jouba/aggregate'
require 'jouba/stores'

module Jouba
  module_function

  class Configuration < Hashie::Mash
    def store
      @store ||= Hashie::Mash.new
    end
  end

  class<<self
    attr_accessor :adapter
    attr_reader :adapters_map
  end

  def adapter
    @adapter ||= config.store.adapter
  end

  def config
    @config ||= Configuration.new
  end

  def configure
    config.tap { |configuration| yield(configuration) }
  end

  def commit(aggregate, event)
    store.append_events(aggregate, event)
  end

  def find(aggregate_class, aggregate_id)
    store.find(aggregate_class, aggregate_id)
  end

  def adapters_map
    @adapters_map ||= {}
  end

  def register_adapter(key, klass)
    adapters_map.merge!(key => klass.new)
  end

  def store
    adapters_map[adapter]  || fail("unknown adapter - valids are #{adapters_map.keys.join(', ')}")
  end
end
