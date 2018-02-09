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

  def get(queue_pid) do
    Queue.get(queue_pid)
  end

  def ack(queue_pid, msg_id) do
    Queue.ack(queue_pid, msg_id)
  end

  def reject(queue_pid, msg_id) do
    Queue.reject(queue_pid, msg_id)
  end
end
