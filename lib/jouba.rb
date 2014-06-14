require 'virtus'
require 'wisper'
require 'hashie'
require 'mongoid'

Dir["#{File.dirname(__FILE__)}/jouba/**/*.rb"].each {|f| require f}

module Jouba
  extend self

  attr_accessor :config

  def configure
    @config = Configuration.new.tap{ |configuration| yield(configuration) }
  end
end
