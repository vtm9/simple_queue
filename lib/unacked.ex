defmodule SimpleQueue.Unacked do
  alias __MODULE__

  def new() do
    %{}
  end

  def add(message, unacked) do
    Map.put(unacked, message.id, message)
  end
end
