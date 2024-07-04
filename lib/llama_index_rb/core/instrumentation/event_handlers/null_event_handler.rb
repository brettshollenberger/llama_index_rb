require_relative "base_event_handler"

module LlamaIndexRb
  module Core
    module Instrumentation
      module EventHandlers
        class NullEventHandler < BaseEventHandler
          # Class method to return the class name
          def self.class_name
            "NullEventHandler"
          end

          # Handle logic - null handler does nothing
          def handle(event, **_kwargs)
            # Do nothing
          end
        end
      end
    end
  end
end
