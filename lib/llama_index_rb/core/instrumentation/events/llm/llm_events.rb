require "active_model"
require "time"
require_relative "../base_event"
require_relative "span"

module LlamaIndexRb
  module Core
    module Instrumentation
      module Events
        module LLM
          class PredictStartEvent < BaseEvent
            include ActiveModel::Model
            include ActiveModel::Attributes

            attribute :template, :object
            attribute :template_args, :hash, default: nil

            def self.class_name
              "PredictStartEvent"
            end
          end

          class PredictEndEvent < BaseEvent
            include ActiveModel::Model
            include ActiveModel::Attributes

            attribute :output, :string

            def self.class_name
              "LLMPredictEndEvent"
            end
          end

          class StructuredPredictStartEvent < BaseEvent
            include ActiveModel::Model
            include ActiveModel::Attributes

            attribute :output_cls, :object
            attribute :template, :object
            attribute :template_args, :hash, default: nil

            def self.class_name
              "LLMStructuredPredictStartEvent"
            end
          end

          class StructuredPredictEndEvent < BaseEvent
            include ActiveModel::Model
            include ActiveModel::Attributes

            attribute :output, :object

            def self.class_name
              "LLMStructuredPredictEndEvent"
            end
          end

          class CompletionStartEvent < BaseEvent
            include ActiveModel::Model
            include ActiveModel::Attributes

            attribute :prompt, :string
            attribute :additional_kwargs, :hash
            attribute :model_dict, :hash

            def self.class_name
              "LLMCompletionStartEvent"
            end
          end

          class CompletionInProgressEvent < BaseEvent
            include ActiveModel::Model
            include ActiveModel::Attributes

            attribute :prompt, :string
            attribute :response, :object

            def self.class_name
              "LLMCompletionInProgressEvent"
            end
          end

          class CompletionEndEvent < BaseEvent
            include ActiveModel::Model
            include ActiveModel::Attributes

            attribute :prompt, :string
            attribute :response, :object

            def self.class_name
              "LLMCompletionEndEvent"
            end
          end

          class ChatStartEvent < BaseEvent
            include ActiveModel::Model
            include ActiveModel::Attributes

            attribute :messages, :array, default: -> { [] }
            attribute :additional_kwargs, :hash
            attribute :model_dict, :hash

            def self.class_name
              "LLMChatStartEvent"
            end
          end

          class ChatInProgressEvent < BaseEvent
            include ActiveModel::Model
            include ActiveModel::Attributes

            attribute :messages, :array, default: -> { [] }
            attribute :response, :object

            def self.class_name
              "LLMChatInProgressEvent"
            end
          end

          class ChatEndEvent < BaseEvent
            include ActiveModel::Model
            include ActiveModel::Attributes

            attribute :messages, :array, default: -> { [] }
            attribute :response, :object, default: nil

            def self.class_name
              "LLMChatEndEvent"
            end
          end
        end
      end
    end
  end
end
