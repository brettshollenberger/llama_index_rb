module LlamaIndexRb
  module Core
    module Instrumentation
      module Span
        ACTIVE_SPAN_ID_KEY = :llama_index_active_span_id

        class << self
          def active_span_id
            # Logger.new(STDOUT).debug("Getting active_span_id for Thread #{Thread.current.object_id}, saw: #{Thread.current[ACTIVE_SPAN_ID_KEY]}")
            Thread.current[ACTIVE_SPAN_ID_KEY]
          end

          def active_span_id=(value)
            Logger.new(STDOUT).debug("Setting active_span_id=#{value} for Thread #{Thread.current.object_id}")
            Thread.current[ACTIVE_SPAN_ID_KEY] = value
          end

          def reset_active_span_id(token = nil)
            # Logger.new(STDOUT).debug("Resetting active_span_id for Thread #{Thread.current.object_id}, to: #{token}")
            Thread.current[ACTIVE_SPAN_ID_KEY] = token
          end
        end
      end
    end
  end
end

# Initialize the active span ID to nil
LlamaIndexRb::Core::Instrumentation::Span.reset_active_span_id
