module LlamaIndexRb
  module Core
    module Callbacks
      class EventContext
        def initialize(callback_manager, event_type, event_id = nil)
          @callback_manager = callback_manager
          @event_type = event_type
          @event_id = event_id || SecureRandom.uuid
          @started = false
          @finished = false
        end

        def on_start(payload: nil, **kwargs)
          return if @started

          @started = true
          @callback_manager.on_event_start(@event_type, payload: payload, event_id: @event_id, **kwargs)
        end

        def on_end(payload: nil, **kwargs)
          return if @finished

          @finished = true
          @callback_manager.on_event_end(@event_type, payload: payload, event_id: @event_id, **kwargs)
        end
      end
    end
  end
end
