defmodule Protohackers.End2End.TimestampedPrices do
  use ExUnit.Case, async: true

  @default_timeout 100

  describe "xxxx" do
    test "yyyy" do
      {:ok, socket} = :gen_tcp.connect(~c"localhost", 5557, mode: :binary, active: false)
      # :gen_tcp.send(socket, Base.decode16!("490000303900000065") <> Base.decode16!("490000303900000065"))
      :ok = :gen_tcp.send(socket, <<?I, 10::32, 100::32>>)
      :ok = :gen_tcp.send(socket, <<?I, 30::32, 200::32>>)
      :ok = :gen_tcp.send(socket, <<?I, 20::32, 150::32>>)
      :ok = :gen_tcp.send(socket, <<?I, 50::32, 800::32>>)

      :ok = :gen_tcp.send(socket, <<?Q, 0::32, 32::32>>)
      assert {:ok, <<150::32>>} = :gen_tcp.recv(socket, 4, @default_timeout)

      :ok = :gen_tcp.send(socket, <<?Q, 0::32, 10::32>>)
      assert {:ok, <<100::32>>} = :gen_tcp.recv(socket, 4, @default_timeout)

      :ok = :gen_tcp.send(socket, <<?Q, 0::32, 1000::32>>)
      assert {:ok, <<313::32>>} = :gen_tcp.recv(socket, 4, @default_timeout)
    end

    test "query when the state is empty" do
      {:ok, socket} = :gen_tcp.connect(~c"localhost", 5557, mode: :binary, active: false)
      :ok = :gen_tcp.send(socket, <<?Q, 0::32, 32::32>>)
      assert {:ok, <<0::32>>} = :gen_tcp.recv(socket, 4, @default_timeout)
    end
  end
end
