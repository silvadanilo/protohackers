defmodule Protohacker.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias Protohacker.Protocol

  @impl true
  def start(_type, _args) do
    children = [
      {Task.Supervisor, name: Server.TaskSupervisor},
      Supervisor.child_spec({Task, fn -> Protocol.Echo.accept(5555) end}, restart: :permanent, id: :echo_server),
      Supervisor.child_spec({Task, fn -> Protocol.PrimeTime.accept(5556) end}, restart: :permanent, id: :prime_server),
      Supervisor.child_spec({Task, fn -> Protocol.TimestampedPrices.accept(5557) end}, restart: :permanent, id: :prices),
      Supervisor.child_spec({Task, fn -> Protocol.BudgetChat.accept(5558) end}, restart: :permanent, id: :budget_chat),
      Supervisor.child_spec({Protocol.Database, 5559}, restart: :permanent, id: :database)
    ]

    opts = [strategy: :one_for_one, name: Protohacker.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
