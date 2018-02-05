defmodule SimpleQueue.Queue do
  use GenServer

  alias __MODULE__
  alias SimpleQueue.{Store, Unacked}
  alias SimpleQueue.Utils.Id

  defstruct(
    # queue data structure
    # in-memory queue head
    head: :queue.new(),
    # on-disk overflow queue tail
    store: nil,
    # in-flight map
    unacked: Unacked.new(),
    # number of message to keep in-memory
    capacity: 10,
    # message visibility timeout, time to keep message in-flight queue
    ttf: 1_000,
    # message time-to-sync
    tts: 100,
    expire_at: System.os_time()
  )

  @timeout Application.get_env(:simple_queue, :timeout)

  # API
  def start_link(dir, params) do
    GenServer.start_link(__MODULE__, [dir, params])
  end

  def add(queue_pid, payload) do
    GenServer.call(queue_pid, {:add, payload}, @timeout)
  end

  def get(queue_pid) do
    GenServer.call(queue_pid, :get, @timeout)
  end

  # SERVER

  def init([dir, params]) do
    {:ok,
     %Queue{
       store: Store.new(dir)
     }}
  end

  def handle_call({:add, payload}, _from, state) do
    new_state = add_(payload, state)
    {:reply, :ok, new_state}
  end

  def handle_call(:get, _from, state) do
    {message, new_state} = get_(state)
    {:reply, message, new_state}
  end

  def handle_cast(:ack, _from, state) do
    # {:reply, {:ok}, state}

    {:stop, :normal, state}
  end

  # def handle_call(:drop, _from, state) do
  #   # {:reply, {:ok}, state}

  #   {:stop, :normal, state}
  # end

  # PRIVATE

  defp add_(payload, state) do
    id = Id.new()

    new_state =
      state
      |> maybe_sync_on_disk_store()

    # deq_in_flight(Uid, _),
    new_store = Store.add(pack(id, payload), new_state.store)
    %Queue{new_state | store: new_store}
  end

  defp get_(state) do
    new_state =
      state
      |> maybe_sync_on_disk_store
      |> maybe_shift_on_disk_store

    %Queue{head: head} = new_state

    case head do
      {[], []} ->
        {:empty, new_state}

      queue ->
        {{:value, message}, new_head} = :queue.out(head)
        new_state = add_to_unacked(message, %Queue{new_state | head: new_head})
        {message, new_state}
    end
  end

  defp maybe_shift_on_disk_store(%Queue{head: {[], []}, store: store, capacity: capacity} = state) do
    {head, new_store} = Store.get(capacity + 1, store)
    %Queue{state | head: head, store: new_store}
  end

  defp maybe_shift_on_disk_store(state) do
    state
  end

  def maybe_sync_on_disk_store(%Queue{store: store, tts: tts, expire_at: expire_at} = state) do
    case System.os_time() do
      now when now > expire_at ->
        %Queue{state | store: Store.sync(store), expire_at: System.os_time() + tts}

      _ ->
        state
    end
  end

  defp add_to_unacked(message, %Queue{unacked: unacked} = state) do
    new_unacked = Unacked.add(message, unacked)
    %Queue{state | unacked: new_unacked}
  end

  defp pack(id, payload) do
    %{id: id, payload: payload}
  end
end
