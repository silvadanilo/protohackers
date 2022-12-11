defmodule Protohacker.Protocol.Echo do
  def accept(port) do
    Server.accept(port, __MODULE__)
  end

  def handle({:ok, data}), do: {:ok, data}
  def handle(error), do: error

  def serve(socket) do
    socket
    |> read_line()
    |> handle()
    |> Server.write_line(socket)

    serve(socket)
  end

  def read_line(socket) do
    :gen_tcp.recv(socket, 0)
  end
end
