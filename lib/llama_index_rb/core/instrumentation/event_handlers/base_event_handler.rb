module LlamaIndexRb
  module Core
    module Instrumentation
      module EventHandlers
        class BaseEventHandler
          # Class method to return the class name
          def self.class_name
            "BaseEventHandler"
          end

          # Abstract method to be implemented by subclasses
          def handle(event, **kwargs)
            raise NotImplementedError, "Subclasses must implement the handle method"
          end

          class Config
            @arbitrary_types_allowed = true

            class << self
              attr_accessor :arbitrary_types_allowed
            end
          end
        end
      end
    end
  end
end
