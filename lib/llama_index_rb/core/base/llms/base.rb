require "forwardable"

class CallbackManager
  def initialize(callbacks = [])
    @callbacks = callbacks
  end

  # Add methods as needed
end

module ChainableMixin
  # Add methods as needed
end

module DispatcherSpanMixin
  # Add methods as needed
end

module BaseComponent
  # Add methods as needed
end

class LLMMetadata
  # Define the structure and methods for LLM metadata
end

class ChatMessage
  attr_reader :role, :content

  def initialize(role, content)
    @role = role
    @content = content
  end
end

class ChatResponse
  attr_reader :content

  def initialize(content)
    @content = content
  end
end

class CompletionResponse
  attr_reader :text

  def initialize(text)
    @text = text
  end
end

class BaseLLM
  include ChainableMixin
  include BaseComponent
  include DispatcherSpanMixin

  def initialize(callback_manager = nil)
    @callback_manager = callback_manager || CallbackManager.new
  end

  attr_reader :callback_manager

  def self.inherited(subclass)
    subclass.define_method(:metadata) do
      raise NotImplementedError, "Subclasses must implement the metadata method"
    end

    subclass.define_method(:chat) do |_messages, **_kwargs|
      raise NotImplementedError, "Subclasses must implement the chat method"
    end

    subclass.define_method(:complete) do |_prompt, formatted: false, **_kwargs|
      raise NotImplementedError, "Subclasses must implement the complete method"
    end

    subclass.define_method(:stream_chat) do |_messages, **_kwargs|
      raise NotImplementedError, "Subclasses must implement the stream_chat method"
    end

    subclass.define_method(:stream_complete) do |_prompt, formatted: false, **_kwargs|
      raise NotImplementedError, "Subclasses must implement the stream_complete method"
    end

    subclass.define_method(:achat) do |_messages, **_kwargs|
      raise NotImplementedError, "Subclasses must implement the achat method"
    end

    subclass.define_method(:acomplete) do |_prompt, formatted: false, **_kwargs|
      raise NotImplementedError, "Subclasses must implement the acomplete method"
    end

    subclass.define_method(:astream_chat) do |_messages, **_kwargs|
      raise NotImplementedError, "Subclasses must implement the astream_chat method"
    end

    subclass.define_method(:astream_complete) do |_prompt, formatted: false, **_kwargs|
      raise NotImplementedError, "Subclasses must implement the astream_complete method"
    end
  end
end
