module LlamaIndexRb
  module Core
    module Callbacks
      class EventStats
        attr_reader :total_secs, :average_secs, :total_count

        def initialize(total_secs: nil, average_secs: nil, total_count: nil)
          @total_secs = total_secs
          @average_secs = average_secs
          @total_count = total_count
        end

        def to_s
          "EventStats(total_secs: #{total_secs}, average_secs: #{average_secs}, total_count: #{total_count})"
        end
      end
    end
  end
end
