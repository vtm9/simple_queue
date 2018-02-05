defmodule SimpleQueue.Utils.Id do
  def new do
    System.os_time(:nanosecond)
  end
end
