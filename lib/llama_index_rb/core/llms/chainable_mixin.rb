require_relative "query_component"

module LlamaIndexRb
  module LLMs
    module ChainableMixin
      # A module that can produce a `QueryComponent` from a set of inputs through
      # `as_query_component`.

      # If plugged in directly into a `QueryPipeline`, the `ChainableMixin` will be
      # converted into a `QueryComponent` with default parameters.
      def self._as_query_component(**kwargs)
        QueryComponent.new(**kwargs)
      end
    end
  end
end
