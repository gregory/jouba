require 'forwardable'
require 'hashie'
require 'wisper'
require 'locality-uuid'

require 'jouba/version'
require 'jouba/key'
require 'jouba/event'
require 'jouba/store'
require 'jouba/cache'

module Jouba
  module_function

  DEFAULTS = {
    Event: Jouba::Event,
    Key:   Jouba::Key,
    Cache: Cache::Null.new,
    Store: Jouba::EventStore.new
  }

  class<<self
    include Wisper::Publisher
    extend Forwardable
    def_delegators :config, :Key, :Event, :Cache, :Store
  end

  def config
    @config ||= Hashie::Mash.new { |h, k| h[k] = DEFAULTS[k] }
  end

  def emit(key , name , data)
    config.Event.new(key: key, name: name, data: data).tap do |event|
      block_given? ? yield(event) : event.track
      publish(key, event)
    end
  end

  def stream(key, params = {})
    config.Event.stream(key, params)
  end
end
