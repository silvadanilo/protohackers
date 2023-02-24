defmodule Chat.Room do
  @moduledoc false

  use GenServer

  alias __MODULE__
  alias Chat.Client

  defstruct clients: []

  @welcome_message "Welcome to budgetchat! What shall I call you?\n"

  @impl true
  def init(_) do
    {:ok, %__MODULE__{}}
  end

  def join(client, name) do
    client
    |> Client.with_name(name)
    |> case do
      {:ok, client} ->
        GenServer.cast(Room, {:join, client})
        {:ok, client}

      error ->
        error
    end
  end

  def say(client, message) do
    GenServer.cast(Room, {:say, client, message})
  end

  def quit(client) do
    GenServer.cast(Room, {:quit, client})
  end

  def connect(socket) do
    client = Client.new(socket)
    GenServer.cast(Room, {:connect, client})

    client
  end

  @impl true
  def handle_cast({:connect, client}, room) do
    Client.send(client, @welcome_message)

    {:noreply, room}
  end

  def handle_cast({:join, client}, room) do
    Client.send(client, "* The room contains: #{people_names(room)}\n")

    new_room =
      room
      |> broadcast(client, "* #{client.name} has entered the room\n")
      |> Map.update!(:clients, fn clients -> [client | clients] end)

    {:noreply, new_room}
  end

  def handle_cast({:say, client, message}, room) do
    broadcast(room, client, "[#{Client.name(client)}] #{message}\n")

    {:noreply, room}
  end

  def handle_cast({:quit, client}, room) do
    new_room =
      room
      |> Map.update!(:clients, fn clients -> Enum.reject(clients, fn joined_client -> joined_client == client end) end)
      |> broadcast(client, "* #{client.name} has left the room\n")

    {:noreply, new_room}
  end

  defp broadcast(room, client, message) do
    room.clients
    |> Enum.reject(fn joined_client -> joined_client == client end)
    |> Enum.each(fn client ->
      Client.send(client, message)
    end)

    room
  end

  defp people_names(room) do
    room.clients
    |> Enum.map(fn client -> Client.name(client) end)
    |> Enum.join(", ")
  end
end
