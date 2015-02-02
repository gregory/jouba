module Jouba
  class Key < Struct.new(:name, :id)
    def self.serialize(name, id)
      "#{name}.#{id}"
    end

    def self.deserialize(key)
      new(*key.split('.')[(0..1)])
    end
  end
end
