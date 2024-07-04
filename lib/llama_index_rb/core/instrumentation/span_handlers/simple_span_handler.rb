require "active_model"
require "thread"
require "time"
require "tree"
require_relative "base_span_handler"
require_relative "../span/simple_span"

module LlamaIndexRb
  module Core
    module Instrumentation
      module SpanHandlers
        class SimpleSpanHandler < BaseSpanHandler
          def self.class_name
            "SimpleSpanHandler"
          end

          def new_span(id_, _bound_args, instance: nil, parent_span_id: nil, **_kwargs)
            SimpleSpan.new(id_: id_, parent_id: parent_span_id)
          end

          def prepare_to_exit_span(id_, _bound_args, instance: nil, result: nil, **_kwargs)
            span = open_spans[id_]
            span.end_time = Time.now
            span.duration = span.end_time - span.start_time
            lock.synchronize { completed_spans << span }
            span
          end

          def prepare_to_drop_span(id_, _bound_args, instance: nil, err: nil, **_kwargs)
            return unless open_spans.key?(id_)

            lock.synchronize do
              span = open_spans[id_]
              span.metadata = { error: err.to_s }
              dropped_spans << span
            end
            open_spans.delete(id_)
          end

          def get_parents
            (completed_spans + dropped_spans).select { |s| s.parent_id.nil? }
          end

          def build_tree_by_parent(parent, acc, spans)
            children = spans.select { |s| s.parent_id == parent.id_ }
            return acc if children.empty?

            updated_spans = spans - children
            children_trees = children.map do |c|
              build_tree_by_parent(parent: c, acc: [c], spans: updated_spans)
            end

            acc + children_trees.flatten
          end

          def get_trace_trees
            all_spans = completed_spans + dropped_spans
            parents = get_parents
            span_groups = parents.map do |p|
              build_tree_by_parent(parent: p, acc: [p], spans: all_spans - [p])
            end.map { |group| group.sort_by(&:start_time) }

            trees = []
            span_groups.each do |grp|
              tree = Tree::TreeNode.new(grp.first.id_, "#{grp.first.id_} (#{grp.first.duration})")
              grp.each do |span|
                next if span == grp.first

                parent_node = tree.find { |node| node.name == span.parent_id }
                parent_node << Tree::TreeNode.new(span.id_, "#{span.id_} (#{span.duration})")
              end
              trees << tree
            end

            trees
          end

          def print_trace_trees
            trees = get_trace_trees
            trees.each do |tree|
              puts tree.print_tree
              puts ""
            end
          end
        end
      end
    end
  end
end
