defmodule Chat.Client do
  @moduledoc false

  defstruct socket: nil, name: nil

  def new(socket), do: %__MODULE__{socket: socket}

  def send(client, message), do: :gen_tcp.send(client.socket, message)

  def with_name(client, name) do
    if valid?(name) do
      {:ok, %{client | name: name}}
    else
      {:error, :invalid_name}
    end
  end

  def name(client), do: client.name

  defp valid?(name) do
    name =~ ~r/^[[:alnum:]]+$/
  end
end
