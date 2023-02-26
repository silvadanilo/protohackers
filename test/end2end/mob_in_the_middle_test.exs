defmodule Protohackers.End2End.MobInTheMiddleTest do
  use ExUnit.Case, async: true

  doctest Protohacker.MITM.MobInTheMiddle, import: true

  @default_timeout 2000
  @port 5560

  @welcome_message "Welcome to budgetchat! What shall I call you?\n"

  alias Chat.Room

  setup_all do
    # {:ok, _pid} = GenServer.start_link(Room, nil, name: Room)

    :ok
  end

  test "boguscoin string is replaced" do
    {:ok, remote_socket} = :gen_tcp.listen(16963, [:binary, packet: :line, active: false, reuseaddr: true])

    {bob_socket, remote_bob_socket} = given_a_joined_socket("Bob", remote_socket)
    {alice_socket, _remote_alice_socket} = given_a_joined_socket("Alice", remote_socket)

    :ok = :gen_tcp.send(bob_socket, "Hi alice, please send payment to 7iKDZEwPZSqIvDnHvVN2r0hUWXD5rHX\n")
    assert_remote_server_receive(remote_bob_socket, "Hi alice, please send payment to 7YWHMfk9JZe0LM0g1ZauHuiSxhI\n")

    assert {:ok, "[Bob] Hi alice, please send payment to 7YWHMfk9JZe0LM0g1ZauHuiSxhI\n"} =
             :gen_tcp.recv(alice_socket, 0, @default_timeout)
  end

  test "checking messages sent 1 character at a time" do
    {:ok, remote_socket} = :gen_tcp.listen(16963, [:binary, packet: :line, active: false, reuseaddr: true])

    {bob_socket, remote_bob_socket} = given_a_joined_socket("Bob", remote_socket)
    {alice_socket, _remote_alice_socket} = given_a_joined_socket("Alice", remote_socket)

    sent_message = "Hi alice, please send payment to 7iKDZEwPZSqIvDnHvVN2r0hUWXD5rHX\n"
    expected_message = "Hi alice, please send payment to 7YWHMfk9JZe0LM0g1ZauHuiSxhI\n"
    expected_broadcasted_message = "[Bob] #{expected_message}"

    assert :ok =
             sent_message
             |> String.codepoints()
             |> Enum.reduce_while(nil, fn char, _acc ->
               case :gen_tcp.send(bob_socket, char) do
                 :ok -> {:cont, :ok}
                 error -> {:halt, error}
               end
             end)

    assert_remote_server_receive(remote_bob_socket, expected_message)

    assert {:ok, ^expected_broadcasted_message} = :gen_tcp.recv(alice_socket, 0, @default_timeout)
  end

  defp assert_remote_server_receive(remote_client, message) do
    assert {:ok, ^message} = :gen_tcp.recv(remote_client.socket, 0, @default_timeout)
    Chat.Room.say(remote_client, String.trim(message))
  end

  defp given_a_joined_socket(name, remote_socket) do
    {:ok, socket} = :gen_tcp.connect(~c"localhost", @port, mode: :binary, active: false)
    {:ok, xxx_socket} = :gen_tcp.accept(remote_socket)

    client = Chat.Room.connect(xxx_socket)
    assert {:ok, @welcome_message} = :gen_tcp.recv(socket, 0, @default_timeout)

    :ok = :gen_tcp.send(socket, "#{name}\n")
    {:ok, message} = :gen_tcp.recv(xxx_socket, 0, @default_timeout)
    {:ok, client} = Chat.Room.join(client, String.trim(message))
    assert {:ok, _} = :gen_tcp.recv(socket, 0, @default_timeout)

    {socket, client}
  end
end
