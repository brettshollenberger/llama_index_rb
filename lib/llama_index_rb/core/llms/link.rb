require "active_model"

module LlamaIndexRb
  module Core
    module LLMs
      class Link
        include ActiveModel::Model
        include ActiveModel::Attributes

        attribute :src, :string
        attribute :dest, :string
        attribute :src_key, :string, default: nil
        attribute :dest_key, :string, default: nil
        attribute :condition_fn, :object, default: nil
        attribute :input_fn, :object, default: nil

        validates :src, presence: true
        validates :dest, presence: true

        def initialize(src:, dest:, src_key: nil, dest_key: nil, condition_fn: nil, input_fn: nil)
          super(src: src, dest: dest, src_key: src_key, dest_key: dest_key, condition_fn: condition_fn, input_fn: input_fn)
        end
      end
    end
  end
end
