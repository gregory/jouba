# Jouba

[![Join the chat at https://gitter.im/gregory/jouba](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/gregory/jouba?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
[![Dependency Status](https://gemnasium.com/gregory/jouba.svg)](https://gemnasium.com/gregory/jouba)
[![Build](https://travis-ci.org/gregory/jouba.png?branch=master)](https://travis-ci.org/gregory/jouba)
[![Coverage](https://coveralls.io/repos/gregory/jouba/badge.svg?branch=master)](https://coveralls.io/r/gregory/jouba?branch=master)

![](https://dl.dropboxusercontent.com/u/19927862/jouba.png)

## Context

Jouba aims to be a minimalist framework in pure ruby for [event sourcing](http://martinfowler.com/eaaDev/EventSourcing.html), [CQRS](http://martinfowler.com/bliki/CQRS.html) ready.

**TL; DR**:

**Event sourcing**:
> The fundamental idea of Event Sourcing is that of ensuring every change to the state of an application is captured in an event object, and that these event objects are themselves stored in the sequence they were applied for the same lifetime as the application state itself.

**CQRS**:
> It's a pattern that I first heard described by Greg Young. At its heart is a simple notion that you can use a different model to update information than the model you use to read information.

## FAQ:

* Is it in production yet?
  * Not that i know of. In my case, not yet since i've been pretty busy with other stuffs and this was initially part of a side project, but i should be pretty reactive for PR/issues so feel free to use/improve it.

## Pub/Sub

Jouba ships with a minimalist API to emit events and subscribe listeners (listeners could operate asynchronously) and retrieve events from the store that is set at `Jouba.config.Store` (by default this will be an [in memory store](https://github.com/gregory/jouba/blob/master/lib/jouba/store.rb#L47).

At it's core, it relies on the excellent [wisper](https://github.com/krisleech/wisper) gem so you have all it's awesomeness for free.

```ruby

Jouba.emit('us.computer1.cpu', :idle, {value: 50})
Jouba.subscribe(Logger.new, on: /.*/, with: :log)
Jouba.subscribe(Graphite, on: /us.*/, with: :post, async: true).on_error do |error, name,payload|
	#DO SOMETHING
end

Jouba.stream('us.computer1.cpu').since(1.month.ago).where({value: ->(v) { v >= 20 }})

class Logger
  def log(params={})
  	puts params.map{|k,v| "#{k}=#{v}"}.join(', ')
  end
end

class Collector
  def post(params={})
    $statsd.increment params[:key]
  end
end
```

## Event Store (stores all events that has happened)

You are free to implement an Event Store as soon as they define `self.stream`and `self.track` methods.

```ruby

  class Store < ActiveRecord::Base
    set_table_name :events

    scope :since, -> (time) { where('timestamp >= ?', time) }

    def self.stream(key, params={})
      where(params).where(key: key)
    end

    def self.track(key, serialized_event)
      create serialized_event
    end
  end

  Jouba.config.Store = Store
  Jouba.emit('us.computer1', :disk, {value: 60})
	Jouba.emit('us.computer1', :cpu, {value: 50}) do |event|
	  #DO SOME STUFFS
    event.track
  end
  Jouba.stream('us.computer1').where(key: 'us.computer1', name: :cpu).count

```

## Aggregate (handles Commands and generates Events based on the current state)

A core concept of CQRS is keeping up to date the state of the data when things changes through commands.
[Aggregate](http://martinfowler.com/bliki/DDD_Aggregate.html) handles command and generate events based on the current state.

Jouba ships with an aggregate module, that provides the host class with an `emit` method in order to emit events to the configured Store (pointed by `Jouba.config.Store`).
On a distributed system, to avoid eventual consistency on reading data from the db, you should rebuild the state of the aggregate by replaying all the events.

After a time, the aggregate could end up with a lot of events, so the trick here is to use what is called a [projection](http://martinfowler.com/eaaDev/EventSourcing.html#ApplicationStateStorage). This has been implemented through a Cach mechanisme, by default [NullCache](https://github.com/gregory/jouba/blob/master/lib/jouba/cache.rb#L5), but you could set it to anything you want.

A UUID will be generated for any new aggregate, [even in distributed environment](https://github.com/groupon/locality-uuid.rb)

```ruby

require 'jouba/aggregate'
class Customer < Hashie::Dash
  include Jouba::Aggregate.new(prefix: :on)

  property :uuid
  property :name

  def self.create(attributes)
    Customer.new(uuid: SecureRandom.uuid).tap do |customer|
      customer.create(attributes.merge(uuid: customer.uuid))
    end
  end

  def create(attributes)
    emit(:created, attributes)
  end

  private

  def on_created(attributes)
    update_attributes!(attributes)
  end
end

Jouba.config.Cache = Jouba::Cache::Memory.new
Jouba.subscribe(CustomerAnalytics, on: /Customer.+/, with: :track)

c = Customer.create({fname: 'foo', lname: 'bar'})
c.fname # => "foo"
c.uuid # => 123
c.to_key # => "Customer.123"

d = Customer.find(c.uuid)
c == d #=> true
Customer.stream(c.uuid).count #=> 1
Customer.stream(c.uuid).first.class #=> Jouba::Event
Customer.stream(c.uuid).first.uuid # 20be0ffc-314a-bd53-7a50-013a65ca76d2

```

Event Sourcing might seem overkill, but this is a little cost comparing to [the advantages](https://lostechies.com/jimmybogard/2011/10/11/event-sourcing-as-a-strategic-advantage/) it will bring to your business

## Event (indicate that something has happened)

If you are unhappy with the structure of Jouba::Event, feel free to implement your own!

You can access/update to the main parts of jouba from the config

```ruby
class MyEvent
  # NOTE: the store is accessible from: Jouba.Store or Jouba.config.Store
  def self.serialize(event); end              # serialize an event
  def self.deserialize(serialized_event); end # deserialize a serialized event
  def self.stream(key, params={}); end        # fetch all the matching events
  def track; end                              # save to the event store
end

Jouba.config.Event = MyEvent
```

## Event Key (generate a key based on the aggregate)

If you feels unhappy with the way Jouba::Key is building keys in the aggregate, feel free to implement your own!

```ruby

class MyKey
  attr_reader :class_name, :uuid

  def initialize(class_name, uuid);
    @class_name, @uuid = class_name, uuid
  end

  def self.serialize(class_name, uuid); end #return a string of a key
  def self.deserialize(string); end # return a new MyKey
end
```

## Repository

Repository is a CQRS concept where you should use repositories to fetch your data for read only. You'll need to keep your repository up to date with all the latest changes.
The way to achieve this with jouba is by having the repository to subscribe to the aggregates. Repository will ideally translate events into state.

```ruby
  class Admin
    include Jouba::Aggregate.new(prefix: :foo)

    def self.create(attributes)
      Admin.new(uuid: SecureRandom.uuid).tap do |admin|
        admin.create(attributes.merge(uuid: admin.uuid))
      end
    end

    def create(attributes)
      emit(:created, attributes)
    end

    private

    def foo_created(attributes)
      update_attributes!(attributes)
    end
  end

  class UserRepository < AR
    set_table_name :users
    # must have a key column

    def self.has_been_created(attributes)
      create(attributes)
    end
  end

  Wisper.subscribe(UserRepository, scope: [:Customer, :Admin], prefix: :has_been) # Note here how 2 aggregates are using the same repository.
```

## Cache

If you feels unhappy with Jouba::Cache, feel free to implement your own!

```ruby

class MyCache
  def fetch(_)
    yield
  end

  def refresh(_, _)
    yield
  end
end

Jouba.config.Cache = MyCache.new
```
## Why Jouba?

Jouba is the name of the parrot i grew up with. He never talked but made a hell lot of noise. Going down the path of event sourcing, you'll have a lot of noise first, but then you'll figure out what to do with it.

## TODO:

* [ ] Better doc (this is a draft :))
* [ ] Locking Mechanisme
* [ ] more examples
* [ ] clean the image
* [ ] Rename EventStore.get/set into stream/track for better consistency

## Contributing to jouba

* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet.
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it.
* Fork the project.
* Start a feature/bugfix branch.
* Commit and push until you are happy with your contribution.
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

## Copyright

Copyright (c) 2014 gregory. See LICENSE.txt for
further details.

