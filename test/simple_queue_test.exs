defmodule SimpleQueueTest do
  use ExUnit.Case
  doctest SimpleQueue

  test "create new queue" do
    {:ok, pid} = SimpleQueue.new("tmp/test")
    assert is_pid(pid) == true
  end

  test "add message to queue" do
    {:ok, pid} = SimpleQueue.new("tmp/test1")

    a = SimpleQueue.add(pid, "message")
    assert a == :ok
  end

  test "get message from empty from queue" do
    {:ok, pid} = SimpleQueue.new("tmp/test2")
    message = SimpleQueue.get(pid)

    assert message == :empty
  end

  test "pass message through queue" do
    {:ok, pid} = SimpleQueue.new("tmp/test3")
    payload = "payload"
    SimpleQueue.add(pid, payload)
    assert %{id: id, payload: ^payload} = SimpleQueue.get(pid)
    assert is_integer(id)
  end

  test "pass 10 MB message through queue" do
    {:ok, pid} = SimpleQueue.new("tmp/test3")
    payload = String.duplicate("1", 1024 * 1024 * 10)

    SimpleQueue.add(pid, payload)

    %{id: id, payload: ^payload} = SimpleQueue.get(pid)
  end
end
