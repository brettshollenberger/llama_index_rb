require "thread"
require "securerandom"
require_relative "span/simple_span"
require_relative "span_handlers/base_span_handler"
require_relative "span_handlers/null_span_handler"
require_relative "events/base_event"
require_relative "event_handlers/base_event_handler"

module LlamaIndexRb
  module Core
    module Instrumentation
      class Dispatcher
        attr_accessor :name, :event_handlers, :span_handlers, :parent_name, :manager, :root_name, :propagate

        def initialize(name: "", event_handlers: [], span_handlers: [SpanHandlers::NullSpanHandler.new], parent_name: "",
                       manager: nil, root_name: "root", propagate: true)
          @name = name
          @event_handlers = event_handlers
          @span_handlers = span_handlers
          @parent_name = parent_name
          @root_name = root_name
          @propagate = propagate
          @mutex = Mutex.new
          @manager = manager || Manager.new(self)
          @manager.add_dispatcher(self) unless @manager.dispatchers.key?(name)
        end

        def parent
          @manager.dispatchers[@parent_name] if @manager
        end

        def root
          @manager.dispatchers[@root_name] if @manager
        end

        def add_event_handler(handler)
          @event_handlers << handler unless @event_handlers.any? { |h| h.class == handler.class }
        end

        def add_span_handler(handler)
          @span_handlers << handler unless @span_handlers.any? { |h| h.class == handler.class }
        end

        def event(event, **kwargs)
          current_dispatcher = self
          while current_dispatcher
            current_dispatcher.event_handlers.each do |handler|
              handler.handle(event, **kwargs)
            rescue StandardError => e
              # Handle or log the exception
            end
            current_dispatcher = current_dispatcher.propagate ? current_dispatcher.parent : nil
          end
        end

        def span_enter(id_, bound_args, instance: nil, parent_id: nil, **kwargs)
          current_dispatcher = self
          while current_dispatcher
            current_dispatcher.span_handlers.each do |handler|
              handler.span_enter(id_, bound_args, instance: instance, parent_id: parent_id, **kwargs)
            rescue StandardError => e
              # Handle or log the exception
            end
            current_dispatcher = current_dispatcher.propagate ? current_dispatcher.parent : nil
          end
          Span.active_span_id = id_
        end

        def span_drop(id_, bound_args, instance: nil, err: nil, **kwargs)
          current_dispatcher = self
          while current_dispatcher
            current_dispatcher.span_handlers.each do |handler|
              handler.span_drop(id_, bound_args, instance: instance, err: err, **kwargs)
            rescue StandardError => e
              # Handle or log the exception
            end
            current_dispatcher = current_dispatcher.propagate ? current_dispatcher.parent : nil
          end
          Span.reset_active_span_id
        end

        def span_exit(id_, bound_args, instance: nil, result: nil, **kwargs)
          current_dispatcher = self
          while current_dispatcher
            current_dispatcher.span_handlers.each do |handler|
              handler.span_exit(id_, bound_args, instance: instance, result: result, **kwargs)
            rescue StandardError => e
              # Handle or log the exception
            end
            current_dispatcher = current_dispatcher.propagate ? current_dispatcher.parent : nil
          end
          Span.reset_active_span_id
        end

        def log_name
          parent ? "#{parent.name}.#{name}" : name
        end
      end

      class Manager
        attr_accessor :dispatchers

        def initialize(root)
          @dispatchers = { root.name => root }
        end

        def add_dispatcher(dispatcher)
          @dispatchers[dispatcher.name] = dispatcher unless @dispatchers.key?(dispatcher.name)
        end
      end
    end
  end
end
