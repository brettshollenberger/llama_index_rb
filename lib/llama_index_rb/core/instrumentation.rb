require_relative "instrumentation/dispatcher"

module LlamaIndexRb
  module Core
    module Instrumentation
      def self.root_dispatcher
        @root_dispatcher ||= Dispatcher.new(name: "root", propagate: false)
      end

      def self.root_manager
        @root_manager ||= Manager.new(root_dispatcher)
      end

      def self.get_dispatcher(name = "root")
        return root_manager.dispatchers[name] if root_manager.dispatchers.key?(name)

        candidate_parent_name = name.split(".")[0...-1].join(".")
        parent_name = if root_manager.dispatchers.key?(candidate_parent_name)
                        candidate_parent_name
                      else
                        "root"
                      end

        new_dispatcher = Dispatcher.new(name: name, root_name: root_dispatcher.name, parent_name: parent_name,
                                        manager: root_manager)
        root_manager.add_dispatcher(new_dispatcher)
        new_dispatcher
      end
    end
  end
end
