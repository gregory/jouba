require 'virtus'
require 'wisper'
require 'hashie'
require 'mongoid'

Dir["#{File.dirname(__FILE__)}/jouba/**/*.rb"].each {|f| require f}

module Jouba
  extend Forwardable
  extend self

  attr_accessor :config
  def_delegators :config, :event_store, :snapshot_store, :storage_strategy, :storage_engine

  def config
    @config || raise(ArgumentError.new("Please set the config first"))
  end

  def configure
    @config = Configuration.new.tap{ |configuration| yield(configuration) }
  end
end
