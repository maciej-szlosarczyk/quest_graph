defmodule RelayWithoutFuss.Program do
  alias RelayWithoutFuss.Quest
  alias RelayWithoutFuss.Repo

  use Ecto.Schema

  schema "programs" do
    has_many :quests, Quest

    field :name, :string
  end

  def query(queryable, info) do
    IO.inspect(queryable)
    IO.inspect(info)

    queryable
  end

  def run_batch(queryable, query, col, inputs, repo_opts) do
    Dataloader.Ecto.run_batch(Repo, queryable, query, col, inputs, repo_opts)
  end
end
