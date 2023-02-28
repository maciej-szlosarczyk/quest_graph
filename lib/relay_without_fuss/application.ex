defmodule RelayWithoutFuss.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      RelayWithoutFuss.Repo,
      # Start the Telemetry supervisor
      RelayWithoutFussWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: RelayWithoutFuss.PubSub},
      # Start the Endpoint (http/https)
      RelayWithoutFussWeb.Endpoint
      # Start a worker by calling: RelayWithoutFuss.Worker.start_link(arg)
      # {RelayWithoutFuss.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: RelayWithoutFuss.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    RelayWithoutFussWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
