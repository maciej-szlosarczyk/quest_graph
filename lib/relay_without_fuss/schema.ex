defmodule RelayWithoutFuss.Schema do
  @moduledoc false

  use Absinthe.Schema

  alias RelayWithoutFuss.Repo
  alias RelayWithoutFuss.{Program, Quest, Resource}

  import_types(RelayWithoutFuss.Schema.Objects)

  @impl true
  def plugins do
    [Absinthe.Middleware.Dataloader] ++ Absinthe.Plugin.defaults()
  end

  @impl true
  def context(ctx) do
    repo_source = Dataloader.Ecto.new(Repo, query: &Repo.query/2, run_batch: &Repo.run_batch/5)

    dataloader =
      Dataloader.new()
      |> Dataloader.add_source(Repo, repo_source)

    Map.put(ctx, :loader, dataloader)
  end

  query do
    @desc """
    A list of program objects paginated with Relay standard.
    """
    field :programs, type: list_of(:program) do
      arg :first, :integer
      arg :last, :integer
      arg :after, :string
      arg :before, :string

      resolve fn _, _ ->
        programs = Repo.all(Program)
        {:ok, programs}
      end
    end

    field :program, type: :program_root_object do
      arg :id, non_null(:id)

      resolve fn %{id: id}, _ ->
        program = Repo.get(Program, id)
        {:ok, program}
      end
    end

    @desc """
    A list of quest objects paginated with Relay standard.
    """
    field :quests, type: list_of(:quest) do
      arg :first, :integer
      arg :last, :integer
      arg :after, :string
      arg :before, :string

      resolve fn _, _ ->
        quests = Repo.all(Quest)
        {:ok, quests}
      end
    end

    field :quest, type: :quest_root_object do
      arg :id, non_null(:id)

      resolve fn %{id: id}, _ ->
        quest = Repo.get(Quest, id)
        {:ok, quest}
      end
    end

    @desc """
    A list of resource objects paginated with Relay standard.
    """
    field :resources, type: list_of(:resource) do
      resolve fn _, _ ->
        resources = Repo.all(Resource)
        {:ok, resources}
      end
    end

    field :resource, type: :resource_root_object do
      arg :id, non_null(:id)

      resolve fn %{id: id}, _ ->
        resource = Repo.get(Resource, id)
        {:ok, resource}
      end
    end
  end
end
