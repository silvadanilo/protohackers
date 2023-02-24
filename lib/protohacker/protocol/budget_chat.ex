defmodule Protohacker.Protocol.BudgetChat do
  @moduledoc false

  alias Chat.Room

  def accept(port) do
    {:ok, _pid} = GenServer.start_link(Room, nil, name: Room)

    Server.accept(port, __MODULE__)
  end

  def init(socket) do
    client = Room.connect(socket)
    {:ok, {:connected, client}}
  end

  def handle(name, {:connected, client}) do
    case Room.join(client, name) do
      {:ok, client} ->
        {:ok, nil, {:joined, client}}

      {:error, reason} ->
        {:error, :disconnect, reason}
    end
  end

  def handle(message, {:joined, client} = state) do
    Room.say(client, message)
    {:ok, nil, state}
  end

  def shutdown({:joined, client} = state) do
    Room.quit(client)
    {:ok, state}
  end

  def shutdown({_, _client} = state) do
    {:ok, state}
  end

  def read_line(socket) do
    read_line(socket, "")
  end

  def read_line(socket, message) do
    case :gen_tcp.recv(socket, 1) do
      {:ok, data} ->
        if data == "\n" do
          {:ok, message}
        else
          read_line(socket, message <> data)
        end

      error ->
        error
    end
  end
end
