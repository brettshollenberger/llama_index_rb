module LlamaIndexRb
  module Core
    module LLMs
      class QueryComponent
        attr_accessor :callback_manager, :params

        def initialize(callback_manager: nil, params: {})
          @callback_manager = callback_manager
          @params = params
          super()
        end

        def partial(**kwargs)
          params.merge!(kwargs)
        end

        def set_callback_manager(callback_manager)
          raise NotImplementedError, "set_callback_manager must be implemented"
        end

        def free_req_input_keys
          input_keys.required_keys - params.keys
        end

        def validate_component_inputs(input)
          input_keys.validate(input.keys.to_set)
          _validate_component_inputs(input)
        end

        def validate_component_outputs(output)
          output_keys.validate(output.keys.to_set)
          _validate_component_outputs(output)
        end

        def run_component(**kwargs)
          kwargs.merge!(params)
          kwargs = validate_component_inputs(kwargs)
          component_outputs = _run_component(**kwargs)
          validate_component_outputs(component_outputs)
        end

        def arun_component(**kwargs)
          kwargs.merge!(params)
          kwargs = validate_component_inputs(kwargs)
          component_outputs = _arun_component(**kwargs)
          validate_component_outputs(component_outputs)
        end

        def sub_query_components
          []
        end

        # Abstract methods to be implemented by subclasses
        def _as_query_component(**kwargs)
          raise NotImplementedError, "_as_query_component must be implemented"
        end

        def _validate_component_inputs(input)
          raise NotImplementedError, "_validate_component_inputs must be implemented"
        end

        def _validate_component_outputs(output)
          output
        end

        def _run_component(**kwargs)
          raise NotImplementedError, "_run_component must be implemented"
        end

        def _arun_component(**kwargs)
          raise NotImplementedError, "_arun_component must be implemented"
        end

        def input_keys
          raise NotImplementedError, "input_keys must be implemented"
        end

        def output_keys
          raise NotImplementedError, "output_keys must be implemented"
        end
      end
    end
  end
end
