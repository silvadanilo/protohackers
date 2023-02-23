defmodule Protohackers.End2End.EchoServerTest do
  use ExUnit.Case, async: true

  @timeout 10_000

  test "echoes anything back" do
    {:ok, socket} = :gen_tcp.connect(~c"localhost", 5555, mode: :binary, active: false)
    assert :gen_tcp.send(socket, "foo") == :ok
    assert :gen_tcp.send(socket, "bar") == :ok
    :gen_tcp.shutdown(socket, :write)
    assert {:ok, "foobar"} == :gen_tcp.recv(socket, 0, @timeout)
  end

  test "handles multiple concurrent connections" do
    tasks =
      for _ <- 1..10 do
        Task.async(fn ->
          {:ok, socket} = :gen_tcp.connect(~c"localhost", 5555, mode: :binary, active: false)
          assert :gen_tcp.send(socket, "foo") == :ok
          assert :gen_tcp.send(socket, "bar") == :ok
          :gen_tcp.shutdown(socket, :write)
          assert {:ok, "foobar"} == drain(socket, [])
        end)
      end

    Enum.each(tasks, &Task.await/1)
  end

  defp drain(socket, buffer) do
    case :gen_tcp.recv(socket, 0, @timeout) do
      {:ok, data} -> drain(socket, [data | buffer])
      {:error, :closed} -> {:ok, buffer |> Enum.reverse() |> Enum.join()}
      error -> error
    end
  end
end
