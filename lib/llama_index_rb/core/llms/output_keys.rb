require "active_model"

module LlamaIndexRb
  module Core
    module LLMs
      class OutputKeys
        include ActiveModel::Model
        include ActiveModel::Attributes

        attribute :required_keys, :set, default: -> { Set.new }

        def self.from_keys(required_keys:)
          new(required_keys: required_keys)
        end

        def validate(input_keys)
          return if input_keys == required_keys

          raise "Input keys #{input_keys.to_a} do not match required keys #{required_keys.to_a}"
        end
      end
    end
  end
end
