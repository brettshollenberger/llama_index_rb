guard :rspec, cmd: "bundle exec rspec" do
  watch(%r{^spec/.+_spec\.rb$}) { |_m| "spec/llama_index_rb/core/instrumentation/dispatcher_spec.rb" }
  watch(%r{^lib/(.+)\.rb$}) { |_m| "spec/llama_index_rb/core/instrumentation/dispatcher_spec.rb" }
end
