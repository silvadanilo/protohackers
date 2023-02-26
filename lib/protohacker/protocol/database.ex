defmodule Protohacker.Protocol.Database do
  @moduledoc false

  require Logger

  use GenServer

  def start_link(port) do
    GenServer.start_link(__MODULE__, port)
  end

  @impl true
  def init(port) do
    # Use erlang's `gen_udp` module to open a socket
    # With options:
    #   - binary: request that data be returned as a `String`
    #   - active: gen_udp will handle data reception, and send us a message `{:udp, socket, address, port, data}` when new data arrives on the socket
    # Returns: {:ok, socket}
    :gen_udp.open(port, [:binary, active: true, ip: {0, 0, 0, 0}])
    Logger.info("Accepting connections on udp port #{port}")
    {:ok, %{"version" => "Ken's Key-Value Store 1.0"}}
  end

  @impl true
  def handle_info({:udp, socket, address, port, data}, db) do
    # punt the data to a new function that will do pattern matching
    case handle_packet(data, db) do
      {:ok, db} ->
        {:noreply, db}

      {:reply, message, db} ->
        :ok = :gen_udp.send(socket, address, port, message)
        {:noreply, db}

      {:stop, reason} ->
        :gen_udp.close(socket)
        {:stop, reason, nil}
    end
  end

  defp handle_packet(data, db) do
    Logger.debug("Received: #{String.trim(data)}")

    if String.contains?(data, "=") do
      handle_insertion(data, db)
    else
      handle_query(data, db)
    end
  end

  defp handle_insertion("version=" <> _, db) do
    {:ok, db}
  end

  defp handle_insertion(data, db) do
    [key, value] = String.split(data, "=", parts: 2)
    {:ok, Map.put(db, key, value)}
  end

  defp handle_query(key, db) do
    {:reply, "#{key}=" <> Map.get(db, key, ""), db}
  end
end
