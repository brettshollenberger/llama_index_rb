# spec/llama_index_rb/core/instrumentation/dispatcher_spec.rb
require "spec_helper"
require "parallel"

module LlamaIndexRb
  module Core
    module Instrumentation
      RSpec.describe Dispatcher do
        # DO NOT EVER USE Dispatcher.new! Use get_dispatcher to make sure the root_manager is used!
        let(:dispatcher) { LlamaIndexRb::Core::Instrumentation.get_dispatcher("test") }
        let(:value_error) { StandardError.new("value error") }
        let(:cancelled_error) { StandardError.new("cancelled error") }

        class TestStartEvent < Events::BaseEvent
          def self.class_name
            "TestStartEvent"
          end
        end

        class TestEndEvent < Events::BaseEvent
          def self.class_name
            "TestEndEvent"
          end
        end

        class TestEventHandler < EventHandlers::BaseEventHandler
          @@events = []

          def self.class_name
            "TestEventHandler"
          end

          def handle(event)
            @@events << event
          end

          def self.events
            @@events
          end

          def self.clear_events
            @@events.clear
          end
        end

        let(:test_event_handler) { TestEventHandler.new }

        before(:each) do
          TestEventHandler.clear_events
          dispatcher.add_event_handler(test_event_handler)
        end

        after(:each) do
          TestEventHandler.clear_events
        end

        class TestProcess
          include LlamaIndexRb::Core::Dispatchable
          dispatchable("test")

          def run(a, b: nil, &block)
            event(TestStartEvent.new)
            raise "Oh no!" if a == -1

            answer = block.call(a, b)
            event(TestEndEvent.new)
            answer
          end
          span :run
        end

        describe "spanning a method + adding events" do
          it "handles function with span and events" do
            result = TestProcess.new.run("hello", b: "world") do |a, b|
              "#{a} #{b}"
            end
            expect(result).to eq("hello world")

            events = TestEventHandler.events
            expect(events.length).to eq(2)
            expect(events[0]).to be_a(TestStartEvent)
            expect(events[1]).to be_a(TestEndEvent)
            expect(events[0].span_id).to_not be_nil
            expect(events[0].span_id).to eq events[1].span_id
          end

          it "handles function with span and raises error" do
            expect do
              TestProcess.new.run(-1)
            end.to raise_error(RuntimeError, "Oh no!")
            events = TestEventHandler.events
            expect(events.count).to eq 2
            expect(events.first.class.class_name).to eq "TestStartEvent"
            expect(events.last.class.class_name).to eq "SpanDropEvent"
            expect(events.last.err_str).to eq "Oh no!"
          end
        end

        describe "spanning async functions" do
          it "handles async function with span and events" do
            result = Parallel.map([1, 2, 3], in_threads: 3) do |num|
              TestProcess.new.run(num, b: 1) do |a, b|
                a + b
              end
            end
            expect(result).to eq [2, 3, 4]

            events = TestEventHandler.events
            expect(events.length).to eq(6)
            event_counts = events.group_by do |event|
              event.class.name.gsub(/LlamaIndexRb::Core::Instrumentation::/, "")
            end.transform_values(&:size)
            expect(event_counts["TestStartEvent"]).to eq 3
            expect(event_counts["TestEndEvent"]).to eq 3

            span_counts = events.group_by(&:span_id).transform_values(&:size)

            expect(span_counts.keys.count).to eq 3
            expect(span_counts.values).to all(eq 2) # Each span gets 2 events, start and end
          end
        end

        describe "spanning async functions with errors" do
          it "handles async function with span and raises error" do
            Parallel.map([-1, -1, -1], in_threads: 3) do |num|
              expect do
                TestProcess.new.run(num, b: 1) do |a, b|
                  a + b
                end
              end.to raise_error
            end
            events = TestEventHandler.events

            event_counts = events.group_by do |event|
              event.class.name.gsub(/LlamaIndexRb::Core::Instrumentation::/, "")
            end.transform_values(&:size)
            expect(event_counts["TestStartEvent"]).to eq 3
            expect(event_counts["Events::SpanDropEvent"]).to eq 3

            span_counts = events.group_by(&:span_id).transform_values(&:size)
            expect(span_counts.keys.count).to eq 3
            expect(span_counts.values).to all(eq 2) # Each span gets 2 events, start and end
          end
        end

        describe "span decorator idempotency" do
          it "ensures span decorator is idempotent", :focus do
            func = proc { 1 }
            expect(dispatcher.span(dispatcher.span(dispatcher.span(func))).call).to eq(1)
            expect(dispatcher.span_enter.call_count).to eq(1)
          end

          it "ensures span decorator is idempotent with other decorators" do
            func = proc { 1 }
            decorator = proc { |f| f }
            expect(dispatcher.span(decorator.call(dispatcher.span(decorator.call(func)))).call).to eq(1)
            expect(dispatcher.span_enter.call_count).to eq(1)
          end
        end

        describe "decorating abstract methods" do
          it "ensures mixin decorates abstract methods" do
            abstract_class = Class.new do
              include DispatcherSpanMixin

              def self.abstract_method
                raise NotImplementedError
              end

              dispatcher.span :abstract_method
            end

            concrete_class = Class.new(abstract_class) do
              def self.abstract_method
                1
              end
            end

            expect(concrete_class.abstract_method).to eq(1)
            expect(dispatcher.span_enter.call_count).to eq(1)
          end

          it "ensures mixin decorates overridden methods" do
            base_class = Class.new do
              include DispatcherSpanMixin

              def self.method
                1
              end

              dispatcher.span :method
            end

            subclass = Class.new(base_class) do
              def self.method
                2
              end
            end

            expect(subclass.method).to eq(2)
            expect(dispatcher.span_enter.call_count).to eq(1)
          end
        end
      end
    end
  end
end
