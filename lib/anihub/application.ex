defmodule Anihub.Application do
  # See https://elixir.hexdocs.pm/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      AnihubWeb.Telemetry,
      Anihub.Repo,
      {DNSCluster, query: Application.get_env(:anihub, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Anihub.PubSub},
      # Start a worker by calling: Anihub.Worker.start_link(arg)
      # {Anihub.Worker, arg},
      # Start to serve requests, typically the last entry
      AnihubWeb.Endpoint
    ]

    # See https://elixir.hexdocs.pm/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Anihub.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    AnihubWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
