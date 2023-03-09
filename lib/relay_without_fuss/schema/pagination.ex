defmodule RelayWithoutFuss.Schema.Pagination do
  require OpenTelemetry.Tracer

  defp parse_before(args) do
    case args do
      %{before: ""} ->
        0

      %{before: before} ->
        before = Base.decode64!(before)
        {_source, id} = :erlang.binary_to_term(before)
        id

      _ ->
        0
    end
  end

  defp parse_after(args) do
    case args do
      %{after: ""} ->
        :infinity

      %{after: after_cursor} ->
        after_cursor = Base.decode64!(after_cursor)
        {_source, id} = :erlang.binary_to_term(after_cursor)
        id

      _ ->
        :infinity
    end
  end

  def between_cursors?(%{id: id}, before_cursor, after_cursor) do
    before_cursor < id and id < after_cursor
  end

  def apply_cursor_to_all_edges(all_edges, before_cursor, after_cursor) do
    Enum.filter(all_edges, fn i -> between_cursors?(i, before_cursor, after_cursor) end)
  end

  def has_previous_page?(edges, before_cursor, after_cursor, first, last) do
    Enum.count(edges) > last
  end

  def callback(items, parent, args) do
    parent_schema = parent.__struct__
    source = parent_schema.__schema__(:source)

    OpenTelemetry.Tracer.with_span "#{__MODULE__}.callback/3" do
      before_cursor = parse_before(args)
      after_cursor = parse_after(args)

      items_after_cursor =
        Enum.filter(items, fn i -> between_cursors?(i, before_cursor, after_cursor) end)

      result =
        case args do
          %{first: first} ->
            after_items =
              Enum.take(items_after_cursor, first)
              |> Enum.map(fn item ->
                cursor = {source, item.id} |> :erlang.term_to_binary() |> Base.encode64()
                %{cursor: cursor, node: item}
              end)

            has_next_page = Enum.count(after_items) > 0
            has_previous_page = 0 > 0
            first = List.first(after_items)
            last = List.last(after_items)

            start_cursor = if first, do: first.cursor
            end_cursor = if last, do: last.cursor

            %{
              edges: after_items,
              edges_count: Enum.count(items),
              internal_all_edges: items,
              page_info: %{
                has_next_page: has_next_page,
                has_previous_page: has_previous_page,
                start_cursor: start_cursor,
                end_cursor: end_cursor
              }
            }

          %{last: last} ->
            after_items =
              Enum.take(items_after_cursor, -last)
              |> Enum.map(fn item ->
                cursor = {"id", item.id} |> :erlang.term_to_binary() |> Base.encode64()
                %{cursor: cursor, node: item}
              end)

            has_next_page = Enum.count(after_items) > 0
            has_previous_page = 0 > 0
            first = List.first(after_items)
            last = List.last(after_items)

            start_cursor = if first, do: first.cursor
            end_cursor = if last, do: last.cursor

            %{
              edges: after_items,
              edges_count: Enum.count(items),
              internal_all_edges: items,
              page_info: %{
                has_next_page: has_next_page,
                has_previous_page: has_previous_page,
                start_cursor: start_cursor,
                end_cursor: end_cursor
              }
            }

            %{
              edges: after_items,
              edges_count: Enum.count(items),
              internal_all_edges: items,
              page_info: %{
                has_next_page: has_next_page,
                has_previous_page: has_previous_page,
                start_cursor: start_cursor,
                end_cursor: end_cursor
              }
            }
        end

      page_info = result.page_info

      OpenTelemetry.Tracer.set_attributes(%{
        has_next_page: page_info.has_next_page,
        has_previous_page: page_info.has_previous_page,
        start_cursor: page_info.start_cursor,
        end_cursor: page_info.end_cursor
      })

      {:ok, result}
    end
  end
end
