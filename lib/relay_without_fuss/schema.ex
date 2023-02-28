defmodule RelayWithoutFuss.Schema do
  @moduledoc false

  use Absinthe.Schema
  import Absinthe.Resolution.Helpers

  alias RelayWithoutFuss.Repo
  alias RelayWithoutFuss.Quest
  alias RelayWithoutFuss.Program
  alias RelayWithoutFuss.Resource

  import_types(RelayWithoutFuss.Schema.Objects)

  @impl true
  def plugins do
    [Absinthe.Middleware.Dataloader] ++ Absinthe.Plugin.defaults()
  end

  @impl true
  def context(ctx) do
    dataloader =
      Dataloader.new()
      |> Dataloader.add_source(
        Quest,
        Dataloader.Ecto.new(Repo, query: &Quest.query/2, run_batch: &Quest.run_batch/5)
      )
      |> Dataloader.add_source(
        Program,
        Dataloader.Ecto.new(Repo, query: &Program.query/2, run_batch: &Program.run_batch/5)
      )
      |> Dataloader.add_source(
        Resource,
        Dataloader.Ecto.new(Repo, query: &Resource.query/2, run_batch: &Resource.run_batch/5)
      )

    Map.put(ctx, :loader, dataloader)
  end

  query do
    field :programs, type: list_of(:program) do
      resolve fn _, _ ->
        Repo.all(Program)
      end
    end

    field :program, type: :program do
    end

    field :quests, type: list_of(:quest) do
    end

    field :quest, type: :quest do
    end

    field :resources, type: list_of(:resource) do
    end

    field :resource, type: :resource do
    end
  end
end
