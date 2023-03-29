defmodule QuestGraph.Schema do
  @moduledoc false

  use Absinthe.Schema

  alias QuestGraph.Schema.Pagination
  alias QuestGraph.Repo
  alias QuestGraph.{Program, Quest, Resource}

  import Ecto.Query, only: [from: 2]

  import_types(QuestGraph.Schema.Objects)

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
    field :programs, type: :program_connection do
      arg :first, :integer
      arg :last, :integer
      arg :after, :string
      arg :before, :string

      resolve fn args, _resolution ->
        query = from p in Program, order_by: [desc: p.id], select: p
        programs = Repo.all(query)
        result = Pagination.callback(programs, nil, args)
        {:ok, result}
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
    field :quests, type: :quest_connection do
      arg :first, :integer
      arg :last, :integer
      arg :after, :string
      arg :before, :string

      resolve fn args, _resolution ->
        query = from q in Quest, order_by: [desc: q.id], select: q
        quests = Repo.all(query)
        result = Pagination.callback(quests, nil, args)
        {:ok, result}
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
    field :resources, type: :resource_connection do
      arg :first, :integer
      arg :last, :integer
      arg :after, :string
      arg :before, :string

      resolve fn args, _ ->
        query = from r in Resource, order_by: [desc: r.id], select: r
        resources = Repo.all(query)
        result = Pagination.callback(resources, nil, args)
        {:ok, result}
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
