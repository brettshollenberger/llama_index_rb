require_relative "instrumentation/dispatcher"
require_relative "instrumentation/span/span"
require_relative "instrumentation/events/span_events"

module LlamaIndexRb
  module Core
    module Dispatchable
      extend ActiveSupport::Concern

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

          define_singleton_method :span do |method_name|
            original_method = instance_method(method_name)
            define_method(method_name) do |*args, **kwargs, &block|
              bound_args = original_method.parameters.map.with_index do |param, i|
                [param[1], args[i]]
              end.to_h.merge(kwargs)
              id_ = "#{method_name}-#{SecureRandom.uuid}"
              parent_id = Core::Instrumentation::Span.active_span_id

              Core::Instrumentation::Span.active_span_id = id_

              dispatcher.span_enter(id_, bound_args, instance: self, parent_id: parent_id)
              Logger.new(STDOUT).debug("Thread #{Thread.current.object_id} set id to #{id_}")

              begin
                result = original_method.bind(self).call(*args, **kwargs, &block)
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
          end
        end
      end
    end
  end
end
