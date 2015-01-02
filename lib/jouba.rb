require 'hashie'
require 'wisper'

require 'jouba/version'
require 'jouba/exceptions'
require 'jouba/event'
require 'jouba/aggregate'
require 'jouba/stores'

module Jouba
  module_function

  def adapters_map
    @adapters_map ||= Hashie::Mash.new do |_, k|
      fail("Unknown adapter #{k}, valids are: #{@adapters_map.keys.join(' ')}")
    end
  end

  def alias_store(alias_name, target)
    stores[alias_name] = stores[target]
  end

  def commit(aggregate, event)
    yield if stores[:events].append_events(aggregate, event)
  end

  def config
    @config ||= Hashie::Mash.new { |_, k| fail("Unknown key #{k}, please use configure to set it up") }
  end

  def find(aggregate_class, aggregate_id)
    stores[:events].find(aggregate_class, aggregate_id)
  end

  def locked?(key)
    stores[:lock].locked?(key)
  end

  def register_adapter(key, klass)
    adapters_map[key] = klass
  end

  def register_store(name)
    yield(config.stores!.send("#{name}!"))
    store_config = config.stores[name]
    adapter = adapters_map[store_config.adapter]
    stores[name] = adapter.new(store_config)
  end

  def stores
    @stores ||= Hashie::Mash.new { |_, k| fail("Unknown store #{k}, valids are: #{@stores.keys.join(' ')}") }
  end

  def with_lock(key)
    fail(LockException.new("#{key} has been locked")) if Jouba.locked?(key)

    begin
      stores[:lock].lock!(key)
      yield
    ensure
      stores[:lock].unlock!(key)
    end
  end
end
