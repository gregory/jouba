module Jouba
  module Stores
    def self.append_events(aggregate, events)
      fail NotImplementedError
    end

    def self.find(id)
      fail NotImplementedError
    end

    def self.count
      fail NotImplementedError
    end

    def self.locked?(key)
      fail NotImplementedError
    end

    def self.lock!(key)
      fail NotImplementedError
    end

    def self.unlock!(key)
      fail NotImplementedError
    end
  end
end
