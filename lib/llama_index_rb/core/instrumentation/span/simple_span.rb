require "active_model"
require "time"
require_relative "base_span"

module LlamaIndexRb
  module Core
    module Instrumentation
      class SimpleSpan < BaseSpan
        include ActiveModel::Model
        include ActiveModel::Attributes

        attribute :start_time, :datetime, default: -> { Time.now }
        attribute :end_time, :datetime, default: nil
        attribute :duration, :float, default: 0.0

        attr_accessor :metadata

        def initialize(start_time: nil, end_time: nil, duration: nil, metadata: {})
          @metadata = metadata
          super()
        end

        # Class method to return the class name
        def self.class_name
          "SimpleSpan"
        end

        # Config class to mimic Pydantic config
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
