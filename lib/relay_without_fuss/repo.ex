defmodule RelayWithoutFuss.Repo do
  use Ecto.Repo,
    otp_app: :relay_without_fuss,
    adapter: Ecto.Adapters.Postgres

  def query(queryable, info) do
    queryable
  end

  def run_batch(queryable, query, col, inputs, repo_opts) do
    Dataloader.Ecto.run_batch(Repo, queryable, query, col, inputs, repo_opts)
  end
end
