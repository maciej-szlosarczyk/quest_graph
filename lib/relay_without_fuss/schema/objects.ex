defmodule RelayWithoutFuss.Schema.Objects do
  use Absinthe.Schema.Notation
  import Absinthe.Resolution.Helpers

  alias RelayWithoutFuss.Program
  alias RelayWithoutFuss.Repo

  def relay_callback(items, _parent, args) do
    case args do
      %{first: first} when first < 0 ->
        {:error, "first must be bigger than zero"}

      %{first: first, last: last} ->
        after_first = Enum.take(items, first)
        after_last = Enum.take(items, -last)

        after_items =
          for item <- items,
              item in after_first,
              item in after_last do
            item
          end

        has_next_page = Enum.count(after_first) > 0
        has_previous_page = Enum.count(after_last) > 0
        first = List.first(after_items)
        last = List.last(after_items)

        start_cursor = if first, do: first.id
        end_cursor = if last, do: last.id

        {:ok,
         %{
           edges: after_items,
           page_info: %{
             has_next_page: has_next_page,
             has_previous_page: has_previous_page,
             start_cursor: start_cursor,
             end_cursor: end_cursor
           }
         }}

      %{first: first} ->
        after_first = Enum.take(items, first)

        after_items =
          for item <- items, item in after_first do
            item
          end

        has_next_page = Enum.count(after_first) > 0
        has_previous_page = 0 > 0
        first = List.first(after_items)
        last = List.last(after_items)

        start_cursor = if first, do: first.id
        end_cursor = if last, do: last.id

        {:ok,
         %{
           edges: after_items,
           page_info: %{
             has_next_page: has_next_page,
             has_previous_page: has_previous_page,
             start_cursor: start_cursor,
             end_cursor: end_cursor
           }
         }}
    end
  end

  interface :node do
    field :id, non_null(:id)
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
  end

  object :quest_connection do
    interface :connection
    is_type_of :connection

    field :edges, list_of(:quest)
    field :page_info, non_null(:page_info)
  end

  object :resource_connection do
    interface :connection
    is_type_of :connection

    field :edges, list_of(:resource)
    field :page_info, non_null(:page_info)
  end

  object :program_connection do
    interface :connection
    is_type_of :connection

    field :edges, list_of(:program)
    field :page_info, non_null(:page_info)
  end

  @desc "A program"
  object :program do
    interface :node
    is_type_of :node

    field :id, non_null(:id)
    field :name, non_null(:string)

    field :quests, :quest_connection do
      arg :first, :integer
      arg :last, :integer
      arg :after, :string
      arg :before, :string

      resolve dataloader(Repo, :quests, callback: &__MODULE__.relay_callback/3)
    end
  end

  @desc "a quest"
  object :quest do
    interface :node
    is_type_of :node

    field :id, non_null(:id)
    field :name, non_null(:string)

    field :resources, :resource_connection do
      arg :first, :integer
      arg :last, :integer
      arg :after, :string
      arg :before, :string

      resolve dataloader(Repo, :resources, callback: &__MODULE__.relay_callback/3)
    end

    field :program, non_null(:program) do
      resolve dataloader(Repo)
    end
  end

  @desc "a resource"
  object :resource do
    interface :node
    is_type_of :node

    field :id, non_null(:id)
    field :name, non_null(:string)

    field :quests, :quest_connection do
      arg :first, :integer
      arg :last, :integer
      arg :after, :string
      arg :before, :string
    end
  end
end
