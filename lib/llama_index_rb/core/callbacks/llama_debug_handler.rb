require "time"
require "logger"
require_relative "rails_handler"
require_relative "cb_event"
require_relative "event_stats"

module LlamaIndexRb
  module Core
    module Callbacks
      class LlamaDebugHandler < RailsHandler
        TIMESTAMP_FORMAT = CBEvent::TIMESTAMP_FORMAT

        attr_reader :event_pairs_by_type, :event_pairs_by_id, :sequential_events

        def initialize(event_starts_to_ignore: [], event_ends_to_ignore: [], print_trace_on_end: true,
                       logger: Logger.new(STDOUT))
          @event_pairs_by_type = Hash.new { |hash, key| hash[key] = [] }
          @event_pairs_by_id = Hash.new { |hash, key| hash[key] = [] }
          @sequential_events = []
          @cur_trace_id = nil
          @trace_map = Hash.new { |hash, key| hash[key] = [] }
          @print_trace_on_end = print_trace_on_end
          super(event_starts_to_ignore: event_starts_to_ignore, event_ends_to_ignore: event_ends_to_ignore, logger: logger)
        end

        def on_event_start(event_type, payload: nil, event_id: nil, parent_id: nil, **_kwargs)
          event = CBEvent.new(event_type, payload: payload, id_: event_id)
          @event_pairs_by_type[event.event_type] << event
          @event_pairs_by_id[event.id_] << event
          @sequential_events << event
          event.id_
        end

        def on_event_end(event_type, payload: nil, event_id: nil, **_kwargs)
          event = CBEvent.new(event_type, payload: payload, id_: event_id)
          @event_pairs_by_type[event.event_type] << event
          @event_pairs_by_id[event.id_] << event
          @sequential_events << event
          @trace_map = Hash.new { |hash, key| hash[key] = [] }
          event.id_
        end

        def get_events(event_type = nil)
          return @event_pairs_by_type[event_type] if event_type

          @sequential_events
        end

        def _get_event_pairs(events)
          event_pairs = Hash.new { |hash, key| hash[key] = [] }
          events.each { |event| event_pairs[event.id_] << event }

          event_pairs.values.sort_by { |pair| Time.strptime(pair[1].time, TIMESTAMP_FORMAT) }
        end

        def _get_time_stats_from_event_pairs(event_pairs)
          total_secs = event_pairs.sum do |pair|
            start_time = Time.strptime(pair[0].time, TIMESTAMP_FORMAT)
            end_time = Time.strptime(pair[-1].time, TIMESTAMP_FORMAT)
            (end_time - start_time).to_f
          end

          EventStats.new(
            total_secs: total_secs,
            average_secs: total_secs / event_pairs.size,
            total_count: event_pairs.size
          )
        end

        def get_event_pairs(event_type = nil)
          events = event_type ? @event_pairs_by_type[event_type] : @sequential_events
          _get_event_pairs(events)
        end

        def get_llm_inputs_outputs
          _get_event_pairs(@event_pairs_by_type[CBEventType::LLM])
        end

        def get_event_time_info(event_type = nil)
          event_pairs = get_event_pairs(event_type)
          _get_time_stats_from_event_pairs(event_pairs)
        end

        def flush_event_logs
          @event_pairs_by_type.clear
          @event_pairs_by_id.clear
          @sequential_events.clear
        end

        def start_trace(trace_id = nil)
          @trace_map.clear
          @cur_trace_id = trace_id
        end

        def end_trace(_trace_id = nil, trace_map = nil)
          @trace_map = trace_map || Hash.new { |hash, key| hash[key] = [] }
          print_trace_map if @print_trace_on_end
        end

        def _print_trace_map(cur_event_id, level = 0)
          event_pair = @event_pairs_by_id[cur_event_id]
          if event_pair.any?
            time_stats = _get_time_stats_from_event_pairs([event_pair])
            indent = " " * level * 2
            logger.info("#{indent}|_#{event_pair[0].event_type} -> #{time_stats.total_secs} seconds")
          end

          @trace_map[cur_event_id].each do |child_event_id|
            _print_trace_map(child_event_id, level + 1)
          end
        end

        def print_trace_map
          logger.info("*" * 10)
          logger.info("Trace: #{@cur_trace_id}")
          _print_trace_map(BASE_TRACE_EVENT, 1)
          logger.info("*" * 10)
        end
      end
    end
  end
end
