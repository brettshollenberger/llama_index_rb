require "active_model"
require "securerandom"

module LlamaIndexRb
  module Core
    module Instrumentation
      class BaseSpan
        include ActiveModel::Model
        include ActiveModel::Attributes

        attribute :id_, :string, default: -> { SecureRandom.uuid }
        attribute :parent_id, :string, default: nil

        # Class method to return the class name
        def self.class_name
          "BaseSpan"
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
