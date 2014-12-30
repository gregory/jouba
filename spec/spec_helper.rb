require 'simplecov'
require 'rspec'

module SimpleCov::Configuration
  def clean_filters
    @filters = []
  end
end

SimpleCov.configure do
  clean_filters
  load_profile 'test_frameworks'
end

ENV['COVERAGE'] && SimpleCov.start do
  add_filter '/.rvm/'
end

require 'jouba'

RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  config.treat_symbols_as_metadata_keys_with_true_values = true

  Jouba.register_adapter(:random, Struct.new('RandomAdapter'))

  Jouba.configure do |jouba_config|
    jouba_config.store.adapter = :random
  end

  config.order = 'random'
end
