require_relative "rails_handler"
require_relative "event_context"

module LlamaIndexRb
  module Core
    module Callbacks
      class CallbackManager < RailsHandler
        module CBEventType
          CHUNKING = "chunking"
          NODE_PARSING = "node_parsing"
          EMBEDDING = "embedding"
          LLM = "llm"
          QUERY = "query"
          RETRIEVE = "retrieve"
          SYNTHESIZE = "synthesize"
          TREE = "tree"
          SUB_QUESTION = "sub_question"
          TEMPLATING = "templating"
          FUNCTION_CALL = "function_call"
          RERANKING = "reranking"
          EXCEPTION = "exception"
          AGENT_STEP = "agent_step"
        end

        module EventPayload
          DOCUMENTS = "documents" # list of documents before parsing
          CHUNKS = "chunks" # list of text chunks
          NODES = "nodes" # list of nodes
          PROMPT = "formatted_prompt" # formatted prompt sent to LLM
          MESSAGES = "messages" # list of messages sent to LLM
          COMPLETION = "completion" # completion from LLM
          RESPONSE = "response" # message response from LLM
          QUERY_STR = "query_str" # query used for query engine
          SUB_QUESTION = "sub_question" # a sub question & answer + sources
          EMBEDDINGS = "embeddings" # list of embeddings
          TOP_K = "top_k" # top k nodes retrieved
          ADDITIONAL_KWARGS = "additional_kwargs" # additional kwargs for event call
          SERIALIZED = "serialized" # serialized object for event caller
          FUNCTION_CALL = "function_call" # function call for the LLM
          FUNCTION_OUTPUT = "function_call_response" # function call output
          TOOL = "tool" # tool used in LLM call
          MODEL_NAME = "model_name" # model name used in an event
          TEMPLATE = "template" # template used in LLM call
          TEMPLATE_VARS = "template_vars"  # template variables used in LLM call
          SYSTEM_PROMPT = "system_prompt"  # system prompt used in LLM call
          QUERY_WRAPPER_PROMPT = "query_wrapper_prompt" # query wrapper prompt used in LLM
          EXCEPTION = "exception" # exception raised in an event
        end

        LEAF_EVENTS = [CBEventType::CHUNKING, CBEventType::LLM, CBEventType::EMBEDDING]

        attr_reader :trace_map, :event_starts_to_ignore, :event_ends_to_ignore

        def initialize(handlers = [])
          @handlers = handlers
          @trace_map = Hash.new { |hash, key| hash[key] = [] }
        end

        def on_event_start(event_type, payload: nil, event_id: nil, parent_id: nil, **kwargs)
          event_id ||= SecureRandom.uuid

          begin
            parent_id ||= GlobalStackTrace.trace.last
          rescue IndexError
            start_trace("llama-index")
            parent_id = GlobalStackTrace.trace.last
          end

          @trace_map[parent_id] << event_id

          @handlers.each do |handler|
            next if handler.event_starts_to_ignore.include?(event_type)

            handler.on_event_start(
              event_type,
              payload: payload,
              event_id: event_id,
              parent_id: parent_id,
              **kwargs
            )
          end

          GlobalStackTrace.add_trace(event_id) unless LEAF_EVENTS.include?(event_type)

          event_id
        end

        def on_event_end(event_type, payload: nil, event_id: nil, **kwargs)
          event_id ||= SecureRandom.uuid

          @handlers.each do |handler|
            next if handler.event_ends_to_ignore.include?(event_type)

            handler.on_event_end(event_type, payload: payload, event_id: event_id, **kwargs)
          end

          return if LEAF_EVENTS.include?(event_type)

          GlobalStackTrace.pop
        end

        def add_handler(handler)
          @handlers << handler
        end

        def remove_handler(handler)
          @handlers.delete(handler)
        end

        def set_handlers(handlers)
          @handlers = handlers
        end

        def start_trace(trace_id: nil)
          current_trace_stack_ids = GlobalStackTrace.trace_ids.dup
          if trace_id
            if current_trace_stack_ids.empty?
              reset_trace_events
              @handlers.each { |handler| handler.start_trace(trace_id: trace_id) }
              current_trace_stack_ids = [trace_id]
            else
              current_trace_stack_ids << trace_id
            end
          end
          GlobalStackTrace.set_trace_ids(current_trace_stack_ids)
        end

        def end_trace(trace_id: nil, trace_map: nil)
          current_trace_stack_ids = GlobalStackTrace.trace_ids.dup
          if trace_id && current_trace_stack_ids.any?
            current_trace_stack_ids.pop
            if current_trace_stack_ids.empty?
              @handlers.each { |handler| handler.end_trace(trace_id: trace_id, trace_map: @trace_map) }
              current_trace_stack_ids = []
            end
          end
          GlobalStackTrace.set_trace_ids(current_trace_stack_ids)
        end

        def event(event_type, payload: nil, event_id: nil)
          event = EventContext.new(self, event_type, event_id: event_id)
          event.on_start(payload: payload)

          payload = nil
          begin
            yield event
          rescue StandardError => e
            payload = { EventPayload::EXCEPTION => e }
            e.instance_variable_set(:@event_added, true) unless e.instance_variable_defined?(:@event_added)
            event.on_end(payload: payload) unless event.finished
            raise
          ensure
            event.on_end(payload: payload) unless event.finished
          end
        end

        def as_trace(trace_id)
          start_trace(trace_id: trace_id)
          yield
        rescue StandardError => e
          on_event_start(CBEventType::EXCEPTION, payload: { EventPayload::EXCEPTION => e })
          e.instance_variable_set(:@event_added, true) unless e.instance_variable_defined?(:@event_added)
          raise
        ensure
          end_trace(trace_id: trace_id)
        end

        def reset_trace_events
          @trace_map.clear
          GlobalStackTrace.clear_trace
        end
      end
    end
  end
end
