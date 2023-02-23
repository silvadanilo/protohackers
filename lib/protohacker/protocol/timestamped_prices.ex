defmodule Protohacker.Protocol.TimestampedPrices do
  @moduledoc false

  alias Protohacker.Repository.Prices

  def accept(port) do
    Server.accept(port, __MODULE__)
  end

  def init() do
    {:ok, Prices.init()}
  end

  def read_line(socket) do
    :gen_tcp.recv(socket, 9)
  end

  def handle(<<?I, timestamp::32-signed-big, price::32-signed-big>>, state) do
    {:ok, nil, Prices.add(state, %{timestamp: timestamp, price: price})}
  end

  def handle(<<?Q, from::32-signed-big, to::32-signed-big>>, state) do
    case Prices.query(state, from, to) do
      nil ->
        {:ok, <<0::32-signed-big>>, state}

      average ->
        {:ok, <<average::32-signed-big>>, state}
    end
  end

  def handle(invalid_request, _state) do
    {:error, :disconnect, "invalid request #{inspect(invalid_request)}"}
  end
end

defmodule Protohacker.Repository.Prices do
  @moduledoc false

  def init(), do: []

  def add(current_state, %{timestamp: timestamp, price: price} = record) do
    [{timestamp, price} | current_state]
  end

  def query(current_state, from, to) do
    current_state
    |> Stream.filter(fn {timestamp, _} -> timestamp >= from and timestamp <= to end)
    |> Stream.map(fn {_, price} -> price end)
    |> Enum.reduce({0, 0}, fn price, {sum, count} -> {sum + price, count + 1} end)
    |> then(fn
      {_sum, 0} -> 0
      {sum, count} -> div(sum, count)
    end)
  end

  @spec mean([number()]) :: float() | nil
  defp mean(list) when is_list(list), do: mean(list, 0, 0)

  defp mean([], 0, 0), do: nil
  defp mean([], t, l), do: (t / l) |> round()

  defp mean([x | xs], t, l) do
    mean(xs, t + x, l + 1)
  end
end
