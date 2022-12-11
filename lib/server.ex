defmodule Server do
  require Logger

  @doc """
  Starts accepting connections on the given `port`.
  """
  def accept(port, module) do
    # The options below mean:
    #
    # 1. `:binary` - receives data as binaries (instead of lists)
    # 2. `packet: :line` - receives data line by line
    # 3. `active: false` - blocks on `:gen_tcp.recv/2` until data is available
    # 4. `reuseaddr: true` - allows us to reuse the address if the listener crashes
    {:ok, socket} = :gen_tcp.listen(port, [:binary, packet: :raw, active: false, reuseaddr: true])
    Logger.info("Accepting connections on port #{port}")
    loop_acceptor(socket, module)
  end

  defp loop_acceptor(socket, module) do
    {:ok, client} = :gen_tcp.accept(socket)
    {:ok, pid} = Task.Supervisor.start_child(Server.TaskSupervisor, fn -> serve(client, module) end)
    :ok = :gen_tcp.controlling_process(client, pid)
    loop_acceptor(socket, module)
  end

  defp serve(socket, module) do
    socket
    |> module.read_line()
    |> debug_log()
    |> module.handle()
    |> write_line(socket)

    serve(socket, module)
  end

  def write_line({:ok, text}, socket) do
    Logger.debug("[#{inspect(self())}] Replyin with: #{text}")
    :gen_tcp.send(socket, text)
  end

  def write_line({:error, error}, _socket) when error in [:enotconn, :closed] do
    # The connection was closed, exit politely
    exit(:shutdown)
    nil
  end

  def write_line({:error, :disconnect, error}, _socket) do
    Logger.warn("[#{inspect(self())}] #{inspect(error)}")
    Logger.warn("[#{inspect(self())}] closing connection")

    exit(:shutdown)
    nil
  end

  defp debug_log({:ok, received}) when is_binary(received), do: {:ok, debug_log(received)}
  defp debug_log(received) when is_binary(received) do
    Logger.debug("[#{inspect(self())}] Received: `#{received}`")
    received
  end

  defp debug_log({:error, :closed} = received) do
    Logger.debug("[#{inspect(self())}] Connection closed")
    received
  end

  defp debug_log(received) do
    Logger.error("Received wrong data: `#{inspect(received)}`")
    received
  end
end
