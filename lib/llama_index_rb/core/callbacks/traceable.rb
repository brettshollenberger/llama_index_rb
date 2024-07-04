require_relative "callback_manager"
require "active_support/concern"
require "logger"

module LlamaIndexRb
  module Core
    module Callbacks
      module Traceable
        extend ActiveSupport::Concern

        included do
          attr_accessor :callback_manager, :logger

          def initialize(*args)
            super(*args)
            @callback_manager ||= LlamaIndexRb::Core::Callbacks::CallbackManager.new
            @logger ||= Logger.new(STDOUT)
          end
        end

        class_methods do
          def trace_method(method_name, trace_id, callback_manager_attr: :callback_manager)
            alias_method "#{method_name}_original".to_sym, method_name

            define_method(method_name) do |*args, &block|
              callback_manager = send(callback_manager_attr)
              unless callback_manager.is_a?(CallbackManager)
                logger.warn("Could not find attribute #{callback_manager_attr} on #{self.class}.")
                return send("#{method_name}_original".to_sym, *args, &block)
              end

              callback_manager.as_trace(trace_id) do
                send("#{method_name}_original".to_sym, *args, &block)
              end
            end
          end
        end
      end
    end
  end
end
