defmodule RelayWithoutFuss.Schema.Objects do
  use Absinthe.Schema.Notation

  import Absinthe.Resolution.Helpers

  alias RelayWithoutFuss.Repo
  alias RelayWithoutFuss.Quest
  alias RelayWithoutFuss.Program
  alias RelayWithoutFuss.Resource

  interface :node do
    field :id, non_null(:id)
    resolve_type(fn _, _ -> :quest end)
  end

  object :page_info do
    field :has_next_page, non_null(:boolean)
    field :has_previous_page, non_null(:boolean)
    field :start_cursor, :string
    field :end_cursor, :string
  end

  interface :connection do
    field :edges, list_of(:node)
    field :page_info, non_null(:page_info)

    resolve_type(fn _, _ -> :quest_connection end)
  end

  object :quest_connection do
    interface(:connection)

    field :edges, list_of(:quest)
    field :page_info, non_null(:page_info)
  end

  object :resource_connection do
    interface(:connection)

    field :edges, list_of(:resource) do
      resolve dataloader(Resource)
    end

    field :page_info, non_null(:page_info)
  end

  object :program_connection do
    interface(:connection)

    field :edges, list_of(:program) do
      resolve dataloader(Programs)
    end

    field :page_info, non_null(:page_info)
  end

  @desc "A program"
  object :program do
    interface(:node)

    field :id, non_null(:id)
    field :name, non_null(:string)
    field :quests, :quest_connection
  end

  @desc "a quest"
  object :quest do
    interface(:node)

    field :id, non_null(:id)
    field :name, non_null(:string)
    field :resources, :resource_connection
    field :programs, :program_connection do
    end
  end

  @desc "a resource"
  object :resource do
    interface(:node)

    field :id, non_null(:id)
    field :name, non_null(:string)
    field :quests, :quest_connection
  end
end
