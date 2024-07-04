require "spec_helper"

RSpec.describe LlamaIndexRb::Core::Callbacks::Traceable do
  # Dummy class to test Traceable
  class DummyClass
    include LlamaIndexRb::Core::Callbacks::Traceable

    def test_method(arg)
      "Original method called with #{arg}"
    end
    trace_method :test_method, "test_trace"
  end

  describe "trace_method" do
    let(:dummy_instance) { DummyClass.new }

    it "calls the original method" do
      expect(dummy_instance.callback_manager).to receive(:start_trace).with(anything).at_least(:once)
      expect(dummy_instance.callback_manager).to receive(:end_trace).with(anything).at_least(:once)
      result = dummy_instance.test_method("argument")
      expect(result).to eq("Original method called with argument")
    end

    context "when callback_manager is missing" do
      let(:dummy_instance) { DummyClass.new }

      before do
        allow(dummy_instance).to receive(:callback_manager).and_return(nil)
      end

      it "logs a warning and calls the original method" do
        expect(dummy_instance.logger).to receive(:warn).with("Could not find attribute callback_manager on DummyClass.")
        result = dummy_instance.test_method("argument")
        expect(result).to eq("Original method called with argument")
      end
    end
  end
end
