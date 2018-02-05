defmodule SimpleQueue.Store do
  alias __MODULE__
  alias SimpleQueue.{Reader, Writer}

  defstruct [:writer, :reader, :len]

  def new(dir) do
    %Store{
      writer: Writer.new(dir),
      reader: Reader.new(dir),
      len: Reader.length(dir)
    }
  end

  def add(message, %Store{writer: writer, len: len} = store) do
    %Store{store | writer: Writer.add(message, writer), len: inc(len)}
  end

  def get(n, store) do
    get(n, :queue.new(), store)
  end

  def get(0, acc, store) do
    {acc, store}
  end

  def get(n, acc, %Store{reader: reader, writer: writer, len: len} = store) do
    case Reader.get(reader) do
      {:eof, new_reader} ->
        case Writer.length(writer) do
          0 ->
            {acc, %Store{store | reader: new_reader, len: 0}}

          _ ->
            {acc, %Store{store | reader: new_reader, len: dec(len)}}
        end

      {message, new_reader} ->
        get(n - 1, :queue.in(message, acc), %Store{store | reader: new_reader, len: dec(len)})
    end
  end

  def sync(%Store{writer: writer} = store) do
    %Store{store | writer: Writer.close_and_rotate(writer)}
  end

  defp inc(:infinity), do: :infinity
  defp inc(x), do: x + 1

  defp dec(:infinity), do: :infinity
  defp dec(x), do: x - 1
end
