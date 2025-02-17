# frozen_string_literal: true

require_relative "lib/llama_index_rb/version"

Gem::Specification.new do |spec|
  spec.name = "llama_index_rb"
  spec.version = LlamaIndexRb::VERSION
  spec.authors = ["Brett Shollenberger"]
  spec.email = ["brettshollenberger@Bretts-MacBook-Pro-2.local"]

  spec.summary = "LlamaIndex for Ruby on Rails Applications"
  spec.description = "LlamaIndex for Ruby on Rails applications"
  spec.homepage = "https://github.com/brettshollenberger/llama_index_rb"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["allowed_push_host"] = "https://github.com/brettshollenberger/llama_index_rb.git"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.metadata["allowed_push_host"]
  spec.metadata["changelog_uri"] = spec.metadata["allowed_push_host"]

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "parallel"
  spec.add_dependency "rails"
end
