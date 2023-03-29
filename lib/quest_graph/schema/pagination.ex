defmodule QuestGraph.Schema.Pagination do
  alias QuestGraph.Schema.Cursor

  defmodule PageInfo do
    alias QuestGraph.Schema.Cursor

    defstruct [:has_previous_page, :has_next_page, :start_cursor, :end_cursor]

    @type t() :: %__MODULE__{
            has_previous_page: boolean(),
            has_next_page: boolean(),
            start_cursor: Cursor.t() | nil,
            end_cursor: Cursor.t() | nil
          }
  end

  defmodule Edge do
    defstruct [:cursor, :node]

    alias QuestGraph.Schema.Cursor

    @type t() :: %__MODULE__{cursor: Cursor.t(), node: %{id: term()}}

    @spec encode(%{:id => term()}) :: t()
    def encode(item), do: %__MODULE__{cursor: Cursor.encode(item), node: item}
  end

  defstruct [:edges, :edges_count, :__all_edges__, :page_info]

  @type t() :: %__MODULE__{
          edges: [Edge.t()],
          edges_count: integer(),
          __all_edges__: [map()],
          page_info: PageInfo.t()
        }

  def is_after_cursor?(_, nil), do: true
  def is_after_cursor?(%{id: id}, cursor), do: id > cursor

  def is_before_cursor?(_, nil), do: true
  def is_before_cursor?(%{id: id}, cursor), do: id < cursor

  @spec apply_relay_pagination([%{id: term()}], map()) ::
          {__MODULE__.t(), %{edges_count: integer()}}
  def apply_relay_pagination(nodes, args) do
    metadata = %{nodes: nodes, args: args}

    :telemetry.span([:quest_graph, :pagination, :apply_relay_pagination], metadata, fn ->
      parsed_args = parse_args(args)
      total_count = Enum.count(nodes)

      result = %__MODULE__{
        edges: [],
        __all_edges__: nodes,
        edges_count: total_count,
        page_info: %PageInfo{}
      }

      first_item = Enum.at(nodes, 0)
      last_item = Enum.at(nodes, -1)

      # First we filter with `after` and `before` arguments.
      cursors_applied =
        nodes
        |> Enum.filter(&is_after_cursor?(&1, parsed_args[:after_cursor]))
        |> Enum.filter(&is_before_cursor?(&1, parsed_args[:before_cursor]))

      result = Map.put(result, :edges, cursors_applied)

      # Then, we apply `first` and `last` arguments to the filtered list.
      after_limit_applied =
        case parsed_args do
          %{first: first} ->
            Enum.take(cursors_applied, first)

          %{last: last} ->
            Enum.take(cursors_applied, -last)

          %{} ->
            cursors_applied
        end

      start_after_limit = Enum.at(after_limit_applied, 0)
      end_after_limit = Enum.at(after_limit_applied, -1)

      start_cursor = if start_after_limit, do: Cursor.encode(start_after_limit)
      end_cursor = if end_after_limit, do: Cursor.encode(end_after_limit)

      has_previous_page = first_item != start_after_limit
      has_next_page = last_item != end_after_limit

      edges = Enum.map(after_limit_applied, &Edge.encode(&1))

      page_info =
        result.page_info
        |> Map.put(:has_next_page, has_next_page)
        |> Map.put(:has_previous_page, has_previous_page)
        |> Map.put(:start_cursor, start_cursor)
        |> Map.put(:end_cursor, end_cursor)

      result =
        result
        |> Map.put(:edges, edges)
        |> Map.put(:page_info, page_info)

      {result, %{edges_count: result.edges_count}}
    end)
  end

  def callback(nodes, parent, args) do
    metadata = %{nodes: nodes, parent: parent, args: args}

    result =
      :telemetry.span([:quest_graph, :pagination, :callback], metadata, fn ->
        {apply_relay_pagination(nodes, args), %{}}
      end)

    {:ok, result}
  end

  @spec parse_args(map()) :: map()
  def parse_args(args) do
    before_cursor = if args[:before], do: args[:before] |> Cursor.decode()
    after_cursor = if args[:after], do: args[:after] |> Cursor.decode()

    %{
      before_cursor: before_cursor,
      after_cursor: after_cursor,
      first: args[:first],
      last: args[:last]
    }
    |> Enum.filter(fn {_k, v} -> v != nil end)
    |> Enum.into(%{})
  end
end
