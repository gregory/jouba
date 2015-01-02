module Jouba
  module Stores
    def self.append_events(_, _)
      fail NotImplementedError
    end

    def self.find(_)
      fail NotImplementedError
    end

    def self.count
      fail NotImplementedError
    end

    def self.locked?(_)
      fail NotImplementedError
    end

    def self.lock!(_)
      fail NotImplementedError
    end

    def self.unlock!(_)
      fail NotImplementedError
    end
  end
end
