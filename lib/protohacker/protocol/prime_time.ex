defmodule Protohacker.Protocol.PrimeTime do
  def accept(port) do
    Server.accept(port, __MODULE__)
  end

  def handle({:ok, data}) do
    parse(data)
  end

  def handle(error), do: error

  def serve(socket) do
    socket
    |> read_line()
    |> handle()
    |> Server.write_line(socket)

    serve(socket)
  end

  def read_line(socket) do
    read_line(socket, "")
  end

  def read_line(socket, message) do
    case :gen_tcp.recv(socket, 1) do
      {:ok, data} ->
        if data == "\n" do
          {:ok, message}
        else
          read_line(socket, message <> data)
        end

      error ->
        error
    end
  end

  defp parse(raw_data) do
    raw_data
    |> String.split("\n")
    |> List.first()
    |> Jason.decode(keys: :atoms)
    |> is_valid()
    |> execute()
  end

  defp execute({:error, error, reason}), do: {:error, error, reason}
  defp execute({:error, error}), do: {:error, :disconnect, error}
  defp execute({:ok, ""}), do: {:ok, ""}

  defp execute({:ok, %{method: "isPrime", number: number}}) when is_number(number) do
    {:ok,
     Jason.encode!(%{
       method: "isPrime",
       prime: is_prime?(number)
     }) <> "\n"}
  end

  defp execute(_), do: {:error, :disconnect, Jason.encode!(%{method: "isPrime", error: "wrong data"})}

  defp is_valid({:ok, parsed_data}), do: {:ok, parsed_data}
  defp is_valid(error), do: {:error, :disconnect, error}

  defp is_prime?(n) when is_float(n), do: false
  defp is_prime?(n) when n in [2, 3], do: true

  defp is_prime?(n) when n > 1 do
    floored_sqrt =
      :math.sqrt(n)
      |> Float.floor()
      |> round

    !Enum.any?(2..floored_sqrt, &(rem(n, &1) == 0))
  end

  defp is_prime?(_n) do
    false
  end
end
