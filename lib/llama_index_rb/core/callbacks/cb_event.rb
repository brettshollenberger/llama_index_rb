require "securerandom"

module LlamaIndexRb
  module Core
    module Callbacks
      class CBEvent
        TIMESTAMP_FORMAT = "%Y-%m-%dT%H:%M:%S.%L%z"

        attr_reader :event_type, :payload, :time, :id_

        def initialize(event_type, payload: nil, time: nil, id_: nil)
          @event_type = event_type
          @payload = payload || {}
          @time = time || Time.current.strftime(TIMESTAMP_FORMAT)
          @id_ = id_ || SecureRandom.uuid
        end

        def to_s
          "CBEvent(type: #{@event_type}, time: #{@time}, id: #{@id_})"
        end

        def ==(other)
          @event_type == other.event_type && @id_ == other.id_
        end
      end
    end
  end
end
