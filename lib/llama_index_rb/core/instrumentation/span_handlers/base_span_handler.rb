require "active_model"
require "thread"
require "securerandom"
require_relative "../span/base_span"

module LlamaIndexRb
  module Core
    module Instrumentation
      module SpanHandlers
        class BaseSpanHandler
          include ActiveModel::Model
          include ActiveModel::Attributes

          attr_accessor :open_spans, :current_span_ids, :completed_spans, :dropped_spans, :lock

          def initialize(attributes = {})
            @open_spans = attributes[:open_spans] || {}
            @current_span_ids = attributes[:current_span_ids] || {}
            @completed_spans = attributes[:completed_spans] || []
            @dropped_spans = attributes[:dropped_spans] || []
            super
            @lock = Mutex.new
          end

          def class_name
            "BaseSpanHandler"
          end

          def span_enter(id_, bound_args, instance: nil, parent_id: nil, **_kwargs)
            return if open_spans.key?(id_)

            span = new_span(id_: id_, bound_args: bound_args, instance: instance, parent_span_id: parent_id)
            return unless span

            @lock.synchronize { open_spans[id_] = span }
          end

          def span_exit(id_, bound_args, instance: nil, result: nil, **_kwargs)
            span = prepare_to_exit_span(id_: id_, bound_args: bound_args, instance: instance, result: result)
            return unless span

            @lock.synchronize { open_spans.delete(id_) }
          end

          def span_drop(id_, bound_args, instance: nil, err: nil, **_kwargs)
            span = prepare_to_drop_span(id_: id_, bound_args: bound_args, instance: instance, err: err)
            return unless span

            @lock.synchronize { open_spans.delete(id_) }
          end

          attr_reader :lock

          private

          def new_span(id_, bound_args, instance: nil, parent_span_id: nil, **kwargs)
            # Subclasses should implement this method to create a new span
            raise NotImplementedError, "Subclasses must implement the `new_span` method."
          end

          def prepare_to_exit_span(id_, bound_args, instance: nil, result: nil, **kwargs)
            # Subclasses should implement this method to prepare a span for exit
            raise NotImplementedError, "Subclasses must implement the `prepare_to_exit_span` method."
          end

          def prepare_to_drop_span(id_, bound_args, instance: nil, err: nil, **kwargs)
            # Subclasses should implement this method to prepare a span for dropping
            raise NotImplementedError, "Subclasses must implement the `prepare_to_drop_span` method."
          end
        end
      end
    end
  end
end
