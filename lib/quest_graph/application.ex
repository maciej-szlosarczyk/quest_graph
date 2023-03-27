defmodule QuestGraph.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    default_attributes = []

    :ok =
      MvOpentelemetry.register_tracer(:plug,
        default_attributes: default_attributes,
        query_params_whitelist: []
      )

    :ok =
      MvOpentelemetry.register_tracer(:ecto,
        span_prefix: [:quest_graph, :repo],
        default_attributes: default_attributes
      )

    :ok = MvOpentelemetry.register_tracer(:absinthe, default_attributes: default_attributes)
    :ok = MvOpentelemetry.register_tracer(:dataloader, default_attributes: default_attributes)

    children = [
      # Start the Ecto repository
      QuestGraph.Repo,
      # Start the Telemetry supervisor
      QuestGraphWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: QuestGraph.PubSub},
      # Start the Endpoint (http/https)
      QuestGraphWeb.Endpoint
      # Start a worker by calling: QuestGraph.Worker.start_link(arg)
      # {QuestGraph.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: QuestGraph.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    QuestGraphWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
