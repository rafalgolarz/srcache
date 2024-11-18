defmodule SRCache.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Starts a worker by calling: SRCache.Worker.start_link(arg)
      # {SRCache.Worker, arg}
      {Task.Supervisor, name: SRCache.TaskSupervisor},
      {Registry, keys: :unique, name: SRCache.Cache.Registry.name()},
      {SRCache.Cache.Manager, []},
      {SRCache.Cache, []}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: SRCache.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
