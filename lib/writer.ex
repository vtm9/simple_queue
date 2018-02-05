defmodule SimpleQueue.Writer do
  alias __MODULE__

  defstruct [:descriptor, :dir, :file, written: 0]

  @extension Application.get_env(:simple_queue, :buffer_extension)
  @chunk Application.get_env(:simple_queue, :chunk)
  @delay Application.get_env(:simple_queue, :delay)
  @segment Application.get_env(:simple_queue, :segment)

  def new(dir) do
    close_and_rotate(%Writer{dir: dir})
  end

  def add(message, writer) do
    %Writer{descriptor: descriptor, written: written} = new_writer = open(writer)
    pack = encode(message)
    :ok = :file.write(descriptor, pack)
    maybe_shift(%Writer{new_writer | written: written + :erlang.iolist_size(pack)})
  end

  defp maybe_shift(%Writer{written: written} = writer) when written >= @segment do
    close_and_rotate(writer)
  end

  defp maybe_shift(writer), do: writer

  # encode message
  defp encode(message) do
    binary_message = :erlang.term_to_binary(message)
    hash = :erlang.crc32(binary_message)
    <<0::16, byte_size(binary_message)::32, hash::32, binary_message::binary>>
  end

  # open file
  defp open(%Writer{descriptor: nil, dir: dir} = writer) do
    today = Date.utc_today() |> to_string
    file = Path.join([dir, today, "sq" <> @extension])
    :ok = :filelib.ensure_dir(file)

    {:ok, descriptor} =
      :file.open(file, [:raw, :binary, :append, :exclusive, {:delayed_write, @chunk, @delay}])

    %Writer{writer | descriptor: descriptor, file: file}
  end

  defp open(writer) do
    writer
  end

  # close any open file and rotate existed spools
  def close_and_rotate(%Writer{descriptor: nil, dir: dir} = writer) do
    Path.join([dir, "*", "sq" <> @extension])
    |> Path.wildcard()
    |> Enum.each(&spool_to_file/1)

    writer
  end

  def close_and_rotate(%Writer{descriptor: descriptor, file: file} = writer) do
    :file.close(descriptor)
    spool_to_file(file)

    %Writer{writer | descriptor: nil, file: nil, written: 0}
  end

  # rename file
  def spool_to_file(file) do
    name = Path.rootname(file, @extension)

    extension =
      System.os_time()
      |> to_string()
      |> Base.encode16()

    :ok = File.rename(file, Path.join([[name, ".", extension]]))
  end

  def length(%Writer{descriptor: nil}), do: 0
  def length(_), do: :infinity
end
