defmodule Protohackers.End2End.PrimeServerTest do
  use ExUnit.Case, async: true

  describe "when a well-formed request is received" do
    test "reply with a well-formed response" do
      {:ok, socket} = :gen_tcp.connect(~c"localhost", 5556, mode: :binary, active: false)
      :gen_tcp.send(socket, Jason.encode!(%{method: "isPrime", number: 7}) <> "\n")

      assert {:ok, data} = :gen_tcp.recv(socket, 0, 2048)
      assert String.ends_with?(data, "\n")
      assert Jason.decode!(data) == %{"method" => "isPrime", "prime" => true}

      :gen_tcp.send(socket, Jason.encode!(%{method: "isPrime", number: 10}) <> "\n")

      assert {:ok, data} = :gen_tcp.recv(socket, 0, 2048)
      assert String.ends_with?(data, "\n")
      assert Jason.decode!(data) == %{"method" => "isPrime", "prime" => false}
    end
  end

  describe "when a malformed request is received" do
    test "reply with a malformed response and close connection" do
      {:ok, socket} = :gen_tcp.connect(~c"localhost", 5556, mode: :binary, active: false)
      :gen_tcp.send(socket, Jason.encode!(%{method: "not-exists", number: 11}) <> "\n")

      assert {:error, :closed} = :gen_tcp.recv(socket, 0, 2048)
    end
  end
end
