module LlamaIndexRb
  module Core
    module Callbacks
      class BaseHandler
        attr_accessor :event_starts_to_ignore, :event_ends_to_ignore

        def initialize(event_starts_to_ignore: [], event_ends_to_ignore: [], **_kwargs)
          @event_starts_to_ignore = event_starts_to_ignore.freeze
          @event_ends_to_ignore = event_ends_to_ignore.freeze
        end

        def on_event_start(event_type, payload: nil, event_id: nil, parent_id: nil, **kwargs)
          raise NotImplementedError, "Subclasses must implement the on_event_start method"
        end

        def on_event_end(event_type, payload: nil, event_id: nil, **kwargs)
          raise NotImplementedError, "Subclasses must implement the on_event_end method"
        end

        def start_trace(trace_id: nil)
          raise NotImplementedError, "Subclasses must implement the start_trace method"
        end

        def end_trace(trace_id: nil, trace_map: nil)
          raise NotImplementedError, "Subclasses must implement the end_trace method"
        end
      end
    end
  end
end
