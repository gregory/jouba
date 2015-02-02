require 'pry' #TODO: remove me
require 'forwardable'
require 'hashie'
require 'locality-uuid'

require 'jouba/version'
require 'jouba/key'
require 'jouba/event'
require 'jouba/store'
require 'jouba/cache'

module Jouba
  module_function

  class<<self
    extend Forwardable
    def_delegators :config, :Key, :Event, :Cache, :Store
  end

  def config
    @config ||= Hashie::Mash.new do |h, k|
      case k
      when 'Event'
        h[k] = Jouba::Event
      when 'Key'
        h[k] = Jouba::Key
      when 'Cache'
        h[k] = Cache::Null.new
      when 'Store'
        h[k] = Jouba::EventStore.new
      else
        nil
      end
    end
  end

  def emit(key , name , data)
    config.Event.new(key: key, name: name, data: data).track
  end

  def stream(key, params={})
    config.Event.stream(key, params)
  end
end
