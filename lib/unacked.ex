defmodule SimpleQueue.Unacked do
  alias __MODULE__

  def new() do
    %{}
  end

  def add(message, unacked) do
    Map.put(unacked, message.id, message)
  end

  def ack(message_id, unacked) do
    Map.delete(unacked, message_id)
  end

  def reject(message_id, unacked) do
    Map.delete(unacked, message_id)
  end

  def get(message_id, unacked) do
    Map.get(unacked, message_id)
  end
end
