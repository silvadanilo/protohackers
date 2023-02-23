defmodule Protohacker.Protocol.Echo do
  @moduledoc false

  @timeout 10_000

  def accept(port) do
    Server.accept(port, __MODULE__)
  end

  def init(), do: {:ok, nil}

  def handle(received_data, state), do: {:ok, received_data, state}

  def read_line(socket) do
    :gen_tcp.recv(socket, 0, @timeout)
  end
end
