defmodule Protohacker.MITM.Listener do
  @moduledoc false

  require Logger

  alias Protohacker.MITM.MobInTheMiddle

  def accept(port) do
    {:ok, socket} = :gen_tcp.listen(port, [:binary, packet: :line, active: true, reuseaddr: true])
    Logger.info("Accepting connections on port #{port}")
    loop_acceptor(socket)
  end

  defp loop_acceptor(socket) do
    {:ok, client_socket} = :gen_tcp.accept(socket)
    {:ok, pid} = GenServer.start_link(MobInTheMiddle, client_socket)
    :gen_tcp.controlling_process(client_socket, pid)

    loop_acceptor(socket)
  end
end
