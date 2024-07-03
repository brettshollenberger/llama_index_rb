require "pry"

RSpec.describe LlamaIndexRb::Core::Callbacks::LlamaDebugHandler do
  let(:test_payload) do
    { "one": 1, "two": 2 }
  end
  let(:test_id) do
    "my id"
  end

  it "on_event_start" do
    handler = described_class.new
    event_id = handler.on_event_start("LLM", payload: test_payload, event_id: test_id)

    expect(event_id).to eq test_id
    expect(handler.event_pairs_by_type.count).to eq 1
    expect(handler.sequential_events.count).to eq 1

    events = handler.event_pairs_by_type["LLM"]
    expect(events.count).to eq 1
    expect(events.first.payload).to eq test_payload
  end

  it "on_event_end" do
    handler = described_class.new
    event_id = handler.on_event_end("EMBEDDING", payload: test_payload, event_id: test_id)

    expect(event_id).to eq test_id
    expect(handler.event_pairs_by_type.count).to eq 1
    expect(handler.sequential_events.count).to eq 1

    events = handler.event_pairs_by_type["EMBEDDING"]
    expect(events.count).to eq 1
    expect(events.first.payload).to eq test_payload
  end

  it "get_event_stats" do
    handler = described_class.new
    event_id = handler.on_event_start("CHUNKING", payload: test_payload)
    handler.on_event_end("CHUNKING", event_id: event_id)

    expect(handler.event_pairs_by_type["CHUNKING"].count).to eq 2
    event_stats = handler.get_event_time_info("CHUNKING")
    expect(event_stats.total_count).to eq 1
    expect(event_stats.total_secs).to eq 0
  end

  it "flush_events" do
    handler = described_class.new

    event_id = handler.on_event_start("CHUNKING", payload: test_payload)
    handler.on_event_end("CHUNKING", event_id: event_id)

    event_id = handler.on_event_start("CHUNKING", payload: test_payload)
    handler.on_event_end("CHUNKING", event_id: event_id)

    expect(handler.event_pairs_by_type["CHUNKING"].count).to eq 4

    handler.flush_event_logs

    expect(handler.event_pairs_by_type.count).to eq 0
    expect(handler.sequential_events.count).to eq 0
  end

  it "ignore_events" do
    handler = described_class.new(
      event_starts_to_ignore: ["CHUNKING"],
      event_ends_to_ignore: ["LLM"]
    )

    manager = LlamaIndexRb::Core::Callbacks::Base.new([handler])

    event_id = manager.on_event_start("CHUNKING", payload: test_payload)
    manager.on_event_end("CHUNKING", event_id: event_id)

    event_id = manager.on_event_start("LLM", payload: test_payload)
    manager.on_event_end("LLM", event_id: event_id)

    event_id = manager.on_event_start("EMBEDDING", payload: test_payload)
    manager.on_event_end("EMBEDDING", event_id: event_id)

    # should have only captured 6 - 2 = 4 events
    expect(handler.sequential_events.count).to eq 4
  end
end
