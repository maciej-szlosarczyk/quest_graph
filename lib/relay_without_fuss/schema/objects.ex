defmodule RelayWithoutFuss.Schema.Objects do
  use Absinthe.Schema.Notation
  import Absinthe.Resolution.Helpers

  alias RelayWithoutFuss.Repo
  alias RelayWithoutFuss.Schema.Relay

  object :page_info do
    field :has_next_page, non_null(:boolean)
    field :has_previous_page, non_null(:boolean)
    field :start_cursor, :string
    field :end_cursor, :string
  end

  interface :node do
    field :id, non_null(:id)
  end

  interface :edge do
    field :cursor, non_null(:string)
    field :node, non_null(:node)
  end

  interface :connection do
    field :edges, list_of(:edge)
    field :edges_count, non_null(:integer)
    field :page_info, non_null(:page_info)
  end

  @desc """
  A nested collection of nodes. This collection cannot be paginated, but for convenience it
  includes a total count of element.

  Depending on the specific implementation, totalCount can be loaded with a separate query,
  by counting items in nodes or with a window function.
  """
  interface :nested_collection do
    field :nodes, list_of(:node)
    field :total_count, non_null(:integer)
  end

  object :program_root_object do
    field :id, non_null(:id)
    field :name, non_null(:string)

    field :quests, :quest_connection do
      arg :first, :integer
      arg :last, :integer
      arg :after, :string
      arg :before, :string

      resolve dataloader(Repo, :quests, callback: &Relay.connection_callback/3)
    end
  end

  object :program do
    interface :node
    is_type_of :node

    field :id, non_null(:id)
    field :name, non_null(:string)

    field :quests, :quest_collection do
      resolve dataloader(Repo, :quests,
                callback: fn items, _, _ ->
                  result = %{nodes: items, total_count: Enum.count(items)}
                  {:ok, result}
                end
              )
    end
  end

  object :quest_root_object do
    field :id, non_null(:id)
    field :name, non_null(:string)

    field :resources, :resource_connection do
      arg :first, :integer
      arg :last, :integer
      arg :after, :string
      arg :before, :string

      resolve dataloader(Repo, :resources, callback: &Relay.connection_callback/3)
    end

    field :program, :program do
      resolve dataloader(Repo, :program)
    end
  end

  object :quest do
    interface :node
    is_type_of :node

    field :id, non_null(:id)
    field :name, non_null(:string)

    field :resources, :resource_collection do
      resolve dataloader(Repo, :resources,
                callback: fn items, _, _ ->
                  result = %{nodes: items, total_count: Enum.count(items)}
                  {:ok, result}
                end
              )
    end

    field :program, :program do
      resolve dataloader(Repo, :program)
    end
  end

  object :quest_collection do
    field :nodes, list_of(:quest)
    field :total_count, non_null(:integer)
  end

  object :quest_edge do
    interface :edge
    is_type_of :edge

    field :cursor, non_null(:string)
    field :node, non_null(:quest)
  end

  object :quest_connection do
    interface :connection
    is_type_of :connection

    field :edges, list_of(:quest_edge)
    field :edges_count, non_null(:integer)
    field :page_info, non_null(:page_info)
  end

  object :resource_root_object do
    field :id, non_null(:id)
    field :name, non_null(:string)

    field :quest, :quest do
      resolve dataloader(Repo, :quest)
    end
  end

  object :resource do
    interface :node
    is_type_of :node

    field :id, non_null(:id)
    field :name, non_null(:string)

    field :quest, :quest do
      resolve dataloader(Repo, :quest)
    end
  end

  object :resource_collection do
    field :nodes, list_of(:resource)
    field :total_count, non_null(:integer)
  end

  object :resource_edge do
    interface :edge
    is_type_of :edge

    field :cursor, non_null(:string)
    field :node, non_null(:resource)
  end

  object :resource_connection do
    interface :connection
    is_type_of :connection

    field :edges, list_of(:resource_edge)
    field :edges_count, non_null(:integer)
    field :page_info, non_null(:page_info)
  end
end
