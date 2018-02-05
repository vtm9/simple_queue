defmodule SimpleQueue do
  alias SimpleQueue.Queue

  def new(dir) do
    new(dir, %{})
  end

  def new(dir, params) do
    Queue.start_link(dir, params)
  end

  def add(queue_pid, message) do
    Queue.add(queue_pid, message)
  end

  def add(queue, msg) do
    Queue.add(queue, msg)
  end

  def get(queue) do
    Queue.get(queue)
  end

  def ack(queue, msg_id) do
    Queue.ack(queue, msg_id)
  end

  def reject(queue, msg_id) do
    Queue.reject(queue, msg_id)
  end
end
