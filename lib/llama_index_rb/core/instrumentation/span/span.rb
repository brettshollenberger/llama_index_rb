module LlamaIndexRb
  module Core
    module Instrumentation
      module Span
        ACTIVE_SPAN_ID_KEY = :llama_index_active_span_id

        class << self
          def active_span_id
            Thread.current[ACTIVE_SPAN_ID_KEY]
          end

          def active_span_id=(value)
            Thread.current[ACTIVE_SPAN_ID_KEY] = value
          end

          def reset_active_span_id(token = nil)
            Thread.current[ACTIVE_SPAN_ID_KEY] = token
          end
        end
      end
    end
  end
end

# Initialize the active span ID to nil
LlamaIndexRb::Core::Instrumentation::Span.reset_active_span_id
