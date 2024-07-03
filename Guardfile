guard :rspec, cmd: "bundle exec rspec" do
  watch(%r{^spec/.+_spec\.rb$}) { |_m| "spec/llama_index_rb/core/callbacks/llama_debug_handler_spec.rb" }
  watch(%r{^lib/(.+)\.rb$}) { |_m| "spec/llama_index_rb/core/callbacks/llama_debug_handler_spec.rb" }
end
