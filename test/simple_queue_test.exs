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
    {:ok, pid} = SimpleQueue.new("tmp/test4")
    payload = String.duplicate("1", 1024 * 1024 * 10)

    SimpleQueue.add(pid, payload)

    %{id: id, payload: ^payload} = SimpleQueue.get(pid)
  end

  test "pass two messages through queue" do
    {:ok, pid} = SimpleQueue.new("tmp/test5")
    payload1 = "payload1"
    payload2 = "payload2"
    SimpleQueue.add(pid, payload1)
    SimpleQueue.add(pid, payload2)

    assert %{id: id, payload: ^payload1} = SimpleQueue.get(pid)
    assert %{id: id, payload: ^payload2} = SimpleQueue.get(pid)
  end

  test "ack real message" do
    {:ok, pid} = SimpleQueue.new("tmp/test6")
    payload = "payload"
    SimpleQueue.add(pid, payload)
    %{id: id, payload: ^payload} = SimpleQueue.get(pid)

    assert :ok = SimpleQueue.ack(pid, id)
    assert :empty = SimpleQueue.get(pid)
  end

  test "reject real message" do
    {:ok, pid} = SimpleQueue.new("tmp/test7")
    payload = "payload"
    SimpleQueue.add(pid, payload)
    %{id: id, payload: ^payload} = SimpleQueue.get(pid)

    assert :ok = SimpleQueue.reject(pid, id)
    assert %{id: id, payload: ^payload} = SimpleQueue.get(pid)
  end
end
