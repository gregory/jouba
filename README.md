# jouba


```ruby
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

  class Admin
    include Jouba::Aggregate.new(prefix: :on)

    def self.create(attributes)
      Admin.new(uuid: SecureRandom.uuid).tap do |admin|
        admin.create(attributes.merge(uuid: admin.uuid))
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


  Jouba.emit('us.computer1.cpu', :idle, {value: 50})
  Jouba.stream('us.computer1.cpu').since(1.month.ago).where({value: ->(v) { v >= 20 }})

  Jouba.subscribe(Logger, on: /.*/, with: :log)

  Jouba.subscribe(Graphite, on: /us.*/, with: :post, async: true).on_error do |error, name,payload|
    #DO SOMETHING
  end

  Jouba.config.Cache = Jouba::Cache::Memory.new
  require 'jouba/aggregate'
  customer_params = { fname: 'foo', lname: 'bar' }

  c = Customer.create(customer_params, true)
  c.fname # => "foo"
  c.uuid # => 123
  c.to_key # => "Customer.123"

  d = Customer.find(c.uuid)

```

```ruby
  class Store < AR
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

  class UserRepository < AR
    set_table_name :users
    # must have a key column

    def self.on_created(attributes)
      create(attributes)
    end
  end

  Wisper.subscribe(UserRepository, scope: [:Customer, :Admin], prefix: :on)
```



## Todo
- write a how to in english :)

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

