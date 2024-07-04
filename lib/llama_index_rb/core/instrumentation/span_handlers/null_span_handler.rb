require "active_model"
require_relative "base_span_handler"
require_relative "../span/base_span"

module LlamaIndexRb
  module Core
    module Instrumentation
      module SpanHandlers
        class NullSpanHandler < BaseSpanHandler
          def self.class_name
            "NullSpanHandler"
          end

          def span_enter(id_, bound_args, instance: nil, **kwargs)
            # No-op
          end

          def span_exit(id_, bound_args, instance: nil, result: nil, **kwargs)
            # No-op
          end

          def new_span(id_, bound_args, instance: nil, parent_span_id: nil, **kwargs)
            # No-op
          end

          def prepare_to_exit_span(id_, bound_args, instance: nil, result: nil, **kwargs)
            # No-op
          end

          def prepare_to_drop_span(id_, bound_args, instance: nil, err: nil, **kwargs)
            # No-op
          end
        end
      end
    end
  end
end
