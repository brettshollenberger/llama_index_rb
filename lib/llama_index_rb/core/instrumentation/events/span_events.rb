require_relative "base_event"

module LlamaIndexRb
  module Core
    module Instrumentation
      module Events
        class SpanDropEvent < BaseEvent
          attr_accessor :err_str

          def initialize(timestamp: nil, id_: nil, span_id: nil, err_str: nil)
            super(timestamp: timestamp, id_: id_, span_id: span_id)
            @err_str = err_str
          end

          def self.class_name
            "SpanDropEvent"
          end
        end
      end
    end
  end
end
