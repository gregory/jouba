module Jouba
  module Extensions
    module Hashie
      module Entity
        def self.included(klass)
          klass.send :include, ::Hashie::Extensions::IndifferentAccess
        end
      end
    end
  end
end
