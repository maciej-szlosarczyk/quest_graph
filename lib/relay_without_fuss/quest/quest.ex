defmodule RelayWithoutFuss.Quest do
  alias RelayWithoutFuss.Resource
  alias RelayWithoutFuss.Repo

  use Ecto.Schema

  schema "quests" do
    has_many :resources, Resource
    belongs_to :program, Program

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
