defmodule QuestGraph.Repo do
  use Ecto.Repo,
    otp_app: :quest_graph,
    adapter: Ecto.Adapters.Postgres

  import Ecto.Query, only: [from: 2]

  def query(queryable, _info) do
    from q in queryable, select: q, order_by: [desc: :id]
  end

  def run_batch(queryable, query, col, inputs, repo_opts) do
    Dataloader.Ecto.run_batch(__MODULE__, queryable, query, col, inputs, repo_opts)
  end
end
