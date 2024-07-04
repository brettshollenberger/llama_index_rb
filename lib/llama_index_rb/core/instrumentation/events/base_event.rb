require "securerandom"
require_relative "../span/span"

module LlamaIndexRb
  module Core
    module Instrumentation
      module Events
        class BaseEvent
          attr_accessor :timestamp, :id_, :span_id

          def initialize(timestamp: nil, id_: nil, span_id: nil)
            @timestamp = timestamp || Time.current
            @id_ = id_ || SecureRandom.uuid
            @span_id = span_id || Span.active_span_id
          end

          # Class method to return the class name
          def self.class_name
            "BaseEvent"
          end

          class Config
            @arbitrary_types_allowed = true
            @copy_on_model_validation = "deep"

            class << self
              attr_accessor :arbitrary_types_allowed, :copy_on_model_validation
            end
          end

          # Instance method to return the event as a hash
          def to_h
            {
              timestamp: timestamp,
              id_: id_,
              span_id: span_id,
              class_name: self.class.class_name
            }
          end
        end
      end
    end
  end
end
