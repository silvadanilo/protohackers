defmodule Protohacker.MITM.MobInTheMiddle do
  @moduledoc false

  use GenServer

  require Logger

  defstruct real_server_socket: nil, client_socket: nil

  # FIXME: those data should be injected for testing purpouse
  # @real_server_address 'chat.protohackers.com'
  @real_server_address 'localhost'
  @real_server_port 16963
  @tony_address "7YWHMfk9JZe0LM0g1ZauHuiSxhI"

  @impl true
  def init(client_socket) do
    {:ok, server_socket} = :gen_tcp.connect(@real_server_address, @real_server_port, mode: :binary, active: true)

    {:ok, %__MODULE__{real_server_socket: server_socket, client_socket: client_socket}}
  end

  @impl true
  def handle_info({:tcp, from_socket, message}, %{real_server_socket: from_socket} = state) do
    Logger.debug("Received from real server: `#{message}`")

    :gen_tcp.send(state.client_socket, tonify(message))

    {:noreply, state}
  end

  def handle_info({:tcp, from_socket, message}, %{client_socket: from_socket} = state) do
    Logger.debug("Received from client: `#{message}`")

    :ok = :gen_tcp.send(state.real_server_socket, tonify(message))

    {:noreply, state}
  end

  def handle_info({:tcp_closed, _}, state) do
    :gen_tcp.close(state.real_server_socket)
    :gen_tcp.close(state.client_socket)

    {:stop, :normal, state}
  end

  @doc ~S"""
  Parses the given `line` into a command.

  ## Examples
    # replace boguscoin address
    iex> tonify("7iKDZEwPZSqIvDnHvVN2r0hUWXD5rHX")
    "7YWHMfk9JZe0LM0g1ZauHuiSxhI"

    # replace all boguscoin addresses
    iex> tonify("foo 7iKDZEwPZSqIvDnHvVN2r0hUWXD5rHX bar 7iKDZEwPZSqIvDnHvVN2r0hUWXD5rHX")
    "foo 7YWHMfk9JZe0LM0g1ZauHuiSxhI bar 7YWHMfk9JZe0LM0g1ZauHuiSxhI"

    # if not starts with 7 is not a boguscoin
    iex> tonify("x 6iKDZEwPZSqIvDnHvVN2r0hUWXD5rHX x")
    "x 6iKDZEwPZSqIvDnHvVN2r0hUWXD5rHX x"

    # 36 chars are not boguscoin address
    iex> tonify("x 723456789012345678901234567890123456 x")
    "x 723456789012345678901234567890123456 x"

    iex> tonify("Hi alice, please send payment to 7iKDZEwPZSqIvDnHvVN2r0hUWXD5rHX")
    "Hi alice, please send payment to 7YWHMfk9JZe0LM0g1ZauHuiSxhI"

  """
  def tonify(message) do
    regex = ~r/(?<=^|\s)7\w{25,34}(?=$|\s)/
    Regex.replace(regex, message, @tony_address)
  end
end
