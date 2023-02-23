defmodule Protohackers.End2End.TimestampedPrices do
  use ExUnit.Case, async: true

  @default_timeout 100

  test "query return the right mean event with unordered insertion" do
    {:ok, socket} = :gen_tcp.connect(~c"localhost", 5557, mode: :binary, active: false)

    :ok = :gen_tcp.send(socket, <<?I, 10::32, 100::32>>)
    :ok = :gen_tcp.send(socket, <<?I, 30::32, 200::32>>)
    :ok = :gen_tcp.send(socket, <<?I, 20::32, 150::32>>)
    :ok = :gen_tcp.send(socket, <<?I, 50::32, 800::32>>)

    :ok = :gen_tcp.send(socket, <<?Q, 0::32, 32::32>>)
    assert {:ok, <<150::32>>} = :gen_tcp.recv(socket, 4, @default_timeout)

    :ok = :gen_tcp.send(socket, <<?Q, 0::32, 10::32>>)
    assert {:ok, <<100::32>>} = :gen_tcp.recv(socket, 4, @default_timeout)

    :ok = :gen_tcp.send(socket, <<?Q, 0::32, 1000::32>>)
    assert {:ok, <<312::32>>} = :gen_tcp.recv(socket, 4, @default_timeout)
  end

  test "result is zero when query with an empty state" do
    {:ok, socket} = :gen_tcp.connect(~c"localhost", 5557, mode: :binary, active: false)
    :ok = :gen_tcp.send(socket, <<?Q, 0::32, 1000::32>>)
    assert {:ok, <<0::32>>} = :gen_tcp.recv(socket, 4, @default_timeout)
  end

  test "socket will be closed when invalid data is sent" do
    {:ok, socket} = :gen_tcp.connect(~c"localhost", 5557, mode: :binary, active: false)
    :ok = :gen_tcp.send(socket, <<?Z, 0::32, 32::32>>)
    assert {:error, :closed} = :gen_tcp.recv(socket, 4, @default_timeout)
  end
end
