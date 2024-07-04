require "set"
require_relative "query_component"
require_relative "../callbacks/traceable"
require_relative "input_keys"
require_relative "output_keys"

module LlamaIndexRb
  module Core
    module LLMs
      class CustomQueryComponent < QueryComponent
        include Traceable

        def _validate_component_inputs(input)
          # NOTE: user can override this method to validate inputs
          # but we do this by default for convenience
          input
        end

        def _run_component(**kwargs)
          raise NotImplementedError, "This component does not support async run."
        end

        def _arun_component(**kwargs)
          raise NotImplementedError, "This component does not support async run."
        end

        def _input_keys
          raise NotImplementedError, "Not implemented yet. Please override this method."
        end

        def _optional_input_keys
          Set.new
        end

        def _output_keys
          raise NotImplementedError, "Not implemented yet. Please override this method."
        end

        def input_keys
          InputKeys.from_keys(
            required_keys: _input_keys,
            optional_keys: _optional_input_keys
          )
        end

        def output_keys
          OutputKeys.from_keys(_output_keys)
        end
      end
    end
  end
end
