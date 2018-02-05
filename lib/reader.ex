defmodule SimpleQueue.Reader do
  alias __MODULE__

  @extension Application.get_env(:simple_queue, :timed_extension)
  @chunk Application.get_env(:simple_queue, :chunk)

  defstruct [:descriptor, :dir, :file, chunk: <<>>]

  def new(dir) do
    %Reader{dir: dir}
  end

  def get(%Reader{chunk: <<>>} = reader) do
    case open(reader) do
      :eof ->
        {:eof, reader}

      new_reader ->
        get(read(new_reader))
    end
  end

  def get(%Reader{chunk: chunk} = reader) do
    case decode(chunk) do
      :noent ->
        get(read(reader))

      {<<>>, new_chunk} ->
        get(%Reader{reader | chunk: new_chunk})

      {message, new_chunk} ->
        {message, %Reader{reader | chunk: new_chunk}}
    end
  end

  # utility function to check length of file segments
  def length(%Reader{dir: dir}) do
    Reader.length(dir)
  end

  def length(dir) do
    pattern = Path.join([dir, "*", "sq", @extension])

    case Path.wildcard(pattern) do
      [] ->
        0

      _ ->
        :infinity
    end
  end

  def open(%Reader{descriptor: nil, dir: dir} = reader) do
    pattern = Path.join([dir, "*", ["sq", @extension]])

    case Path.wildcard(pattern) do
      [] ->
        :eof

      [head | _] ->
        {:ok, descriptor} = :file.open(head, [:raw, :binary, :read, {:read_ahead, @chunk}])
        %Reader{reader | descriptor: descriptor, file: head}
    end
  end

  def open(reader), do: reader

  defp read(%Reader{descriptor: descriptor, chunk: head_chunk} = reader) do
    case :file.read(descriptor, @chunk) do
      :eof ->
        close(reader)

      {:ok, chunk} ->
        %Reader{reader | chunk: <<head_chunk::binary, chunk::binary>>}
    end
  end

  # close any open file and rotate active head
  defp close(%Reader{descriptor: nil} = reader), do: reader

  defp close(%Reader{descriptor: descriptor, file: file} = reader) do
    :ok = :file.close(descriptor)
    :ok = :file.delete(file)
    :file.del_dir(Path.dirname(file))
    %Reader{reader | descriptor: nil, file: nil, chunk: <<>>}
  end

  # decode message from memory buffer
  defp decode(<<0::16, len::32, hash::32, tail::binary>>) do
    case byte_size(tail) do
      x when x < len ->
        :noent

      _ ->
        <<binary_message::binary-size(len), rest::binary>> = tail

        case :erlang.crc32(binary_message) do
          hash -> {:erlang.binary_to_term(binary_message), rest}
          _ -> {<<>>, rest}
        end
    end
  end

  defp decode(x) when byte_size(x) < 64 do
    :noent
  end

  defp decode(<<_::8, tail::binary>>) do
    decode(tail)
  end
end
