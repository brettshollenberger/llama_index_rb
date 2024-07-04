module LlamaIndexRb
  module Core
    module LLMs
      class ComponentIntermediates
        attr_accessor :inputs, :outputs

        def initialize(inputs:, outputs:)
          @inputs = inputs
          @outputs = outputs
        end

        def to_s
          "ComponentIntermediates(inputs=#{@inputs}, outputs=#{@outputs})"
        end

        alias inspect to_s
      end
    end
  end
end
