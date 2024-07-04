require_relative "instrumentation/dispatcher"
require_relative "instrumentation/span/span"
require_relative "instrumentation/events/span_events"

module LlamaIndexRb
  module Core
    module Dispatchable
      extend ActiveSupport::Concern

      class DecorationManager
        @decorated_methods = {}

        class << self
          attr_reader :decorated_methods

          def add_method(klass, method_name)
            @decorated_methods[klass] ||= []
            @decorated_methods[klass] << method_name
          end

          def method_decorated?(klass, method_name)
            @decorated_methods[klass]&.include?(method_name)
          end

          def remove_method(klass, method_name)
            return unless @decorated_methods[klass]

            @decorated_methods[klass].delete(method_name)
          end

          def clear
            @decorated_methods.clear
          end
        end
      end

      included do
        def dispatcher
          @dispatcher ||= LlamaIndexRb::Core::Instrumentation.get_dispatcher(self.class.name)
        end

        def event(event, **kwargs)
          dispatcher.event(event, **kwargs)
        end
      end

      class_methods do
        def dispatchable(dispatcher_name)
          define_method :dispatcher do
            @dispatcher ||= LlamaIndexRb::Core::Instrumentation.get_dispatcher(dispatcher_name)
          end

          @event_config = {}
          @span_methods = []
          @decorating = false

          define_singleton_method :events do |method_name, config|
            @event_config[method_name.to_sym] = config
          end

          define_singleton_method :span do |method_name|
            @span_methods << method_name.to_sym
            apply_span_decorator(method_name) if method_defined?(method_name)
          end

          def method_added(method_name)
            return if @decorating

            if @span_methods.present? && @span_methods.include?(method_name) && instance_method(method_name).owner == self
              apply_span_decorator(method_name)
            end

            super
          end

          def apply_span_decorator(method_name)
            return if @decorating
            return if DecorationManager.method_decorated?(self, method_name)

            @decorating = true

            original_method = instance_method(method_name)

            define_method(method_name) do |*args, **kwargs, &block|
              events = (self.class.instance_variable_get(:@event_config) || {}).dig(method_name) || {}
              bound_args = original_method.parameters.map.with_index do |param, i|
                [param[1], args[i]]
              end.to_h.merge(kwargs)
              id_ = "#{method_name}-#{SecureRandom.uuid}"
              parent_id = Core::Instrumentation::Span.active_span_id

              Core::Instrumentation::Span.active_span_id = id_

              dispatcher.span_enter(id_, bound_args, instance: self, parent_id: parent_id)

              begin
                event(events[:start].new) if events.key?(:start)
                result = original_method.bind(self).call(*args, **kwargs, &block)
                event(events[:end].new) if events.key?(:end)
                dispatcher.span_exit(id_, bound_args, instance: self, result: result)
                result
              rescue StandardError => e
                dispatcher.event(LlamaIndexRb::Core::Instrumentation::Events::SpanDropEvent.new(span_id: id_,
                                                                                                err_str: e.message))
                dispatcher.span_drop(id_, bound_args, instance: self, err: e)
                raise e
              ensure
                Core::Instrumentation::Span.active_span_id = parent_id
              end
            end
            DecorationManager.add_method(self, method_name)
            @decorating = false
          end

          def inherited(subclass)
            super
            subclass.instance_variable_set(:@event_config, @event_config.dup)
            subclass.instance_variable_set(:@span_methods, @span_methods.dup)
            subclass.instance_variable_set(:@decorating, false)

            @span_methods.each do |method_name|
              subclass.apply_span_decorator(method_name) if subclass.method_defined?(method_name)
              DecorationManager.remove_method(subclass, method_name) # allow redecoration for redefined methods
            end
          end
        end
      end
    end
  end
end
