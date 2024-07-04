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

          def run_async(a)
            a * 2
          end
          span :run_async
          events :run_async, start: TestStartEvent, end: TestEndEvent

          def parallel_run(n)
            Parallel.map((1..n).to_a, in_threads: 3) do |num|
              run_async(num)
            end
          end
          span :parallel_run
          events :parallel_run, start: TestStartEvent, end: TestEndEvent
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

        describe "spanning async functions + capturing the entire span" do
          it "handles the entire span" do
            result = TestProcess.new.parallel_run(3)
            expect(result).to eq [2, 4, 6]

            events = TestEventHandler.events
            expect(events.length).to eq(8)
            event_counts = events.group_by do |event|
              event.class.name.gsub(/LlamaIndexRb::Core::Instrumentation::/, "")
            end.transform_values(&:size)
            expect(event_counts["TestStartEvent"]).to eq 4
            expect(event_counts["TestEndEvent"]).to eq 4

            span_counts = events.group_by(&:span_id).transform_values(&:size)

            expect(span_counts.keys.count).to eq 4
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
          it "ensures span decorator is idempotent" do
            class TestProcess
              span :run
              span :run
              span :run
            end

            instance = TestProcess.new.run(1, b: 1) { |a, b| a + b }
            events = TestEventHandler.events
            expect(events.count).to eq 2
            expect(events.first).to be_a(TestStartEvent)
            expect(events.last).to be_a(TestEndEvent)
          end
        end

        describe "subclassing" do
          it "ensures mixin decorates abstract methods" do
            class AbstractClass
              include LlamaIndexRb::Core::Dispatchable
              dispatchable("test")

              def abstract_method
                raise NotImplementedError
              end
              span :abstract_method
              events :abstract_method, start: TestStartEvent, end: TestEndEvent
            end

            class ConcreteClass < AbstractClass
              def abstract_method
                1
              end
            end

            expect(dispatcher).to receive(:span_enter).once
            expect(ConcreteClass.new.abstract_method).to eq(1)
            events = TestEventHandler.events
            expect(events.count).to eq 2
          end

          it "ensures mixin decorates overridden methods" do
            class ParentClass
              include LlamaIndexRb::Core::Dispatchable
              dispatchable("test")

              def original_method
                1
              end
              span :original_method
              events :original_method, start: TestStartEvent, end: TestEndEvent
            end

            class SubClass < ParentClass
              def original_method
                2
              end
            end

            expect(dispatcher).to receive(:span_enter).once
            expect(SubClass.new.original_method).to eq(2)
            events = TestEventHandler.events
            expect(events.count).to eq 2
          end
        end
      end
    end
  end
end
