require_relative "base_handler"
require "active_support/logger"

module LlamaIndexRb
  module Core
    module Callbacks
      class RailsHandler < BaseHandler
        def initialize(event_starts_to_ignore: [], event_ends_to_ignore: [], logger: nil)
          @logger = logger || Logger.new(STDOUT)
          super(event_starts_to_ignore: event_starts_to_ignore, event_ends_to_ignore: event_ends_to_ignore)
        end

        # Delegate logging methods to the logger
        %i[debug info warn error fatal unknown].each do |method|
          define_method(method) do |message|
            @logger.send(method, message)
          end
        end

        private

        def _print(message)
          debug(message) # Default to debug level for _print method
        end
      end
    end
  end
end
