defmodule Protohackers.End2End.UdpDatabaseTest do
  use ExUnit.Case, async: true

  @default_timeout 100
  @port 5559

  test "simple insertion" do
    {:ok, socket} = :gen_udp.open(0, [:binary, active: false])

    :ok = udp_send(socket, "foo=bar")
    :ok = udp_send(socket, "foo")

    assert {:ok, {_address, _port, "foo=bar"}} = :gen_udp.recv(socket, @default_timeout)
  end

  test "value could be replaced" do
    {:ok, socket} = :gen_udp.open(0, [:binary, active: false])

    :ok = udp_send(socket, "foo=bar")
    :ok = udp_send(socket, "foo")
    assert {:ok, {_address, _port, "foo=bar"}} = :gen_udp.recv(socket, @default_timeout)

    :ok = udp_send(socket, "foo=baz")
    :ok = udp_send(socket, "foo")
    assert {:ok, {_address, _port, "foo=baz"}} = :gen_udp.recv(socket, @default_timeout)

    :ok = udp_send(socket, "foo=bang")
    :ok = udp_send(socket, "foo")
    assert {:ok, {_address, _port, "foo=bang"}} = :gen_udp.recv(socket, @default_timeout)
  end

  test "value could be empty" do
    {:ok, socket} = :gen_udp.open(0, [:binary, active: false])

    :ok = udp_send(socket, "foo=")
    :ok = udp_send(socket, "foo")
    assert {:ok, {_address, _port, "foo="}} = :gen_udp.recv(socket, @default_timeout)
  end

  test "value could contains =" do
    {:ok, socket} = :gen_udp.open(0, [:binary, active: false])

    :ok = udp_send(socket, "foo=bar=baz")
    :ok = udp_send(socket, "foo")
    assert {:ok, {_address, _port, "foo=bar=baz"}} = :gen_udp.recv(socket, @default_timeout)
  end

  test "value could be just = signs" do
    {:ok, socket} = :gen_udp.open(0, [:binary, active: false])

    :ok = udp_send(socket, "foo===")
    :ok = udp_send(socket, "foo")
    assert {:ok, {_address, _port, "foo==="}} = :gen_udp.recv(socket, @default_timeout)
  end

  test "key could be an empty string" do
    {:ok, socket} = :gen_udp.open(0, [:binary, active: false])

    :ok = udp_send(socket, "=foo")
    :ok = udp_send(socket, "")
    assert {:ok, {_address, _port, "=foo"}} = :gen_udp.recv(socket, @default_timeout)
  end

  test "version key has a default value and could not be overwritten" do
    {:ok, socket} = :gen_udp.open(0, [:binary, active: false])

    :ok = udp_send(socket, "version=my value")
    :ok = udp_send(socket, "version")

    assert {:ok, {_address, _port, "version=Ken's Key-Value Store 1.0"}} = :gen_udp.recv(socket, @default_timeout)
  end

  defp udp_send(socket, message) do
    :gen_udp.send(socket, {127, 0, 0, 1}, @port, message)
  end
end
