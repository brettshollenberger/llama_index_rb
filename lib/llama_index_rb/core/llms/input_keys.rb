require "active_model"

module LlamaIndexRb
  module Core
    module LLMs
      class InputKeys
        include ActiveModel::Model
        include ActiveModel::Attributes

        attribute :required_keys, :set, default: -> { Set.new }
        attribute :optional_keys, :set, default: -> { Set.new }

        def self.from_keys(required_keys:, optional_keys: Set.new)
          new(required_keys: required_keys, optional_keys: optional_keys)
        end

        def validate(input_keys)
          unless required_keys.subset?(input_keys)
            raise "Required keys #{required_keys.to_a} are not present in input keys #{input_keys.to_a}"
          end

          return if input_keys.subset?(required_keys.union(optional_keys))

          raise "Input keys #{input_keys.to_a} contain keys not in required or optional keys #{required_keys.union(optional_keys).to_a}"
        end

        def length
          required_keys.size + optional_keys.size
        end

        def all
          required_keys.union(optional_keys)
        end
      end
    end
  end
end
