require "active_model"
require "time"
require_relative "../base_event"
require_relative "../span"

module LlamaIndexRb
  module Core
    module Instrumentation
      module Events
        module ChatEngine
          class StreamChatStartEvent < BaseEvent
            include ActiveModel::Model
            include ActiveModel::Attributes

            def self.class_name
              "StreamChatStartEvent"
            end
          end

          class StreamChatEndEvent < BaseEvent
            include ActiveModel::Model
            include ActiveModel::Attributes

            def self.class_name
              "StreamChatEndEvent"
            end
          end

          class StreamChatErrorEvent < BaseEvent
            include ActiveModel::Model
            include ActiveModel::Attributes

            attribute :exception, :object

            def self.class_name
              "StreamChatErrorEvent"
            end
          end

          class StreamChatDeltaReceivedEvent < BaseEvent
            include ActiveModel::Model
            include ActiveModel::Attributes

            attribute :delta, :string

            def self.class_name
              "StreamChatDeltaReceivedEvent"
            end
          end
        end
      end
    end
  end
end
