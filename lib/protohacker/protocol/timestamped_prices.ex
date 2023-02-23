defmodule Protohacker.Protocol.TimestampedPrices do
  @moduledoc false

  alias Protohacker.Repository.Prices

  def accept(port) do
    Server.accept(port, __MODULE__)
  end

  def init() do
    {:ok, Prices.init()}
  end

  def handle(data, state) do
    execute(data, state)
  end

  # def handle(error, state), do: error

  def read_line(socket) do
    read_line(socket, "")
  end

  def read_line(socket, message) do
    :gen_tcp.recv(socket, 9)
  end

  defp execute(<<?I, timestamp::32, price::32>>, state) do
    {:ok, nil, Prices.add(state, %{timestamp: timestamp, price: price})}
  end

  defp execute(<<?Q, from::32, to::32>>, state) do
    case Prices.query(state, from, to) do
      nil ->
        {:ok, <<0::32>>, state}
      average ->
        {:ok, <<average::32>>, state}
    end
  end
end

defmodule Protohacker.Repository.Prices do
  @moduledoc false

  def init(), do: []

  def add(current_state, %{timestamp: timestamp, price: price} = record) do
    [record | current_state]
  end

  def query(current_state, from, to) do
    current_state
    |> Enum.filter(fn %{timestamp: timestamp} -> timestamp >= from and timestamp <= to end)
    |> Enum.map(fn %{price: price} -> price end)
    |> mean()
  end

  @spec mean([number()]) :: float() | nil
  defp mean(list) when is_list(list), do: mean(list, 0, 0)

  defp mean([], 0, 0), do: nil
  defp mean([], t, l), do: t / l |> round()

  defp mean([x | xs], t, l) do
    mean(xs, t + x, l + 1)
  end
end
