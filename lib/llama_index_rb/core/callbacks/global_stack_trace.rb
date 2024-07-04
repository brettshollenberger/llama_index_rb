module LlamaIndexRb
  module Core
    module Callbacks
      module GlobalStackTrace
        GLOBAL_TRACE_KEY = :llama_index_global_stack_trace
        BASE_TRACE_EVENT = "base_trace_event".freeze
        EMPTY_TRACE_IDS = [].freeze

        def self.trace
          Thread.current[GLOBAL_TRACE_KEY] ||= [BASE_TRACE_EVENT]
        end

        def self.trace_ids
          Thread.current[GLOBAL_TRACE_KEY] ||= EMPTY_TRACE_IDS
        end

        def self.add_trace(event)
          trace << event
        end

        def self.add_trace_id(id)
          trace_ids << id
        end

        def self.clear_trace
          Thread.current[GLOBAL_TRACE_KEY] = [BASE_TRACE_EVENT]
        end

        def self.clear_trace_ids
          Thread.current[GLOBAL_TRACE_KEY] = EMPTY_TRACE_IDS
        end

        def self.pop
          Thread.current[GLOBAL_TRACE_KEY].pop
        end

        def self.set_trace_ids(trace_ids)
          Thread.current[GLOBAL_TRACE_KEY] = trace_ids
        end
      end
    end
  end
end
