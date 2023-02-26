defmodule Server do
  @moduledoc false

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

    :gen_tcp.controlling_process(client, pid)
    loop_acceptor(socket, module)
  end

  defp serve(socket, module) do
    state =
      socket
      |> module.init()
      |> case do
        {:ok, state} -> state
        {:error, _reason} -> exit(:shutdown)
      end

    serve(socket, module, state)
  end

  defp serve(socket, module, state) do
    new_state =
      with {:ok, data} <- read_line(socket, module),
           {:ok, response, new_state} <- module.handle(data, state) do
        Logger.debug("[#{inspect(self())}] new state: `#{inspect(state)}`")
        Logger.debug("[#{inspect(self())}] response: `#{inspect(response)}`")

        write_line(socket, response)

        new_state
      else
        {:error, error} when error in [:enotconn, :closed] ->
          {:ok, state} = module.shutdown(state)
          exit(:shutdown)
          state

        {:error, :disconnect, error} ->
          Logger.warn("[#{inspect(self())}] #{inspect(error)}")
          Logger.warn("[#{inspect(self())}] closing connection")

          :gen_tcp.close(socket)
          exit(:shutdown)
          state

        :error ->
          :gen_tcp.close(socket)
          exit(:shutdown)
          state
      end

    serve(socket, module, new_state)
  end

  def read_line(socket, module) do
    socket
    |> module.read_line()
    |> log_received_data()
  end

  def write_line(_socket, nil), do: :ok

  def write_line(socket, text) do
    Logger.debug("[#{inspect(self())}] Replyin with: `#{inspect(text)}`")
    :gen_tcp.send(socket, text)
  end

  defp log_received_data({:ok, received}) when is_bitstring(received),
    do: {:ok, log_received_data(received)}

  defp log_received_data(received) when is_bitstring(received) do
    if String.valid?(received) do
      Logger.debug("[#{inspect(self())}] Received: `#{received}`")
    else
      Logger.debug("[#{inspect(self())}] Received: `#{inspect(received)}`")
    end

    received
  end

  defp log_received_data({:error, :closed} = received) do
    Logger.debug("[#{inspect(self())}] Connection closed")
    received
  end

  defp log_received_data(received) do
    Logger.error("Received wrong data: `#{inspect(received)}`")
    received
  end
end
