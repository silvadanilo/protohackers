defmodule Protohackers.End2End.BudgetChatTest do
  use ExUnit.Case, async: true

  @default_timeout 100
  @port 5558

  @welcome_message "Welcome to budgetchat! What shall I call you?\n"

  test "a welcome message is sent on every connection" do
    {:ok, bob_socket} = :gen_tcp.connect(~c"localhost", @port, mode: :binary, active: false)
    {:ok, charlie_socket} = :gen_tcp.connect(~c"localhost", @port, mode: :binary, active: false)

    assert {:ok, @welcome_message} = :gen_tcp.recv(bob_socket, 0, @default_timeout)
    assert {:ok, @welcome_message} = :gen_tcp.recv(charlie_socket, 0, @default_timeout)
  end

  test "chat messages are sent to every people but sender" do
    {:ok, bob_socket} = :gen_tcp.connect(~c"localhost", @port, mode: :binary, active: false)
    assert {:ok, @welcome_message} = :gen_tcp.recv(bob_socket, 0, @default_timeout)

    {:ok, charlie_socket} = :gen_tcp.connect(~c"localhost", @port, mode: :binary, active: false)
    assert {:ok, @welcome_message} = :gen_tcp.recv(charlie_socket, 0, @default_timeout)

    {:ok, dave_socket} = :gen_tcp.connect(~c"localhost", @port, mode: :binary, active: false)
    assert {:ok, @welcome_message} = :gen_tcp.recv(dave_socket, 0, @default_timeout)

    :ok = :gen_tcp.send(bob_socket, "Bob\n")
    assert {:ok, "* The room contains: \n"} = :gen_tcp.recv(bob_socket, 0, @default_timeout)

    :ok = :gen_tcp.send(charlie_socket, "Charlie\n")
    assert {:ok, "* The room contains: Bob\n"} = :gen_tcp.recv(charlie_socket, 0, @default_timeout)
    assert {:ok, "* Charlie has entered the room\n"} = :gen_tcp.recv(bob_socket, 0, @default_timeout)

    :ok = :gen_tcp.send(dave_socket, "Dave\n")
    assert {:ok, "* The room contains: Charlie, Bob\n"} = :gen_tcp.recv(dave_socket, 0, @default_timeout)
    assert {:ok, "* Dave has entered the room\n"} = :gen_tcp.recv(bob_socket, 0, @default_timeout)
    assert {:ok, "* Dave has entered the room\n"} = :gen_tcp.recv(charlie_socket, 0, @default_timeout)

    :ok = :gen_tcp.send(charlie_socket, "Hello, world\n")
    assert {:ok, "[Charlie] Hello, world\n"} = :gen_tcp.recv(dave_socket, 0, @default_timeout)
    assert {:ok, "[Charlie] Hello, world\n"} = :gen_tcp.recv(bob_socket, 0, @default_timeout)
    assert {:error, :timeout} = :gen_tcp.recv(charlie_socket, 0, @default_timeout)

    :ok = :gen_tcp.send(bob_socket, "Hello, charlie\n")
    assert {:ok, "[Bob] Hello, charlie\n"} = :gen_tcp.recv(charlie_socket, 0, @default_timeout)
    assert {:ok, "[Bob] Hello, charlie\n"} = :gen_tcp.recv(dave_socket, 0, @default_timeout)
    assert {:error, :timeout} = :gen_tcp.recv(bob_socket, 0, @default_timeout)

    :gen_tcp.close(dave_socket)
    assert {:ok, "* Dave has left the room\n"} = :gen_tcp.recv(charlie_socket, 0, @default_timeout)
    assert {:ok, "* Dave has left the room\n"} = :gen_tcp.recv(bob_socket, 0, @default_timeout)
  end

  test "invalid name are refused" do
    {:ok, socket} = :gen_tcp.connect(~c"localhost", @port, mode: :binary, active: false)
    assert {:ok, @welcome_message} = :gen_tcp.recv(socket, 0, @default_timeout)

    :ok = :gen_tcp.send(socket, "*\n")
    assert {:error, :closed} = :gen_tcp.recv(socket, 0, @default_timeout)
  end
end
