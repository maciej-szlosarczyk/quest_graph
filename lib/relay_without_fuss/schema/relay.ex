defmodule RelayWithoutFuss.Schema.Relay do
  require OpenTelemetry.Tracer

  def count_edges(parent, _args, _context) do
    OpenTelemetry.Tracer.with_span "RelayWithoutFuss.Schema.Relay.count_edges/3", %{} do
      count = Enum.count(parent.internal_all_edges)
      OpenTelemetry.Tracer.set_attributes(%{count: count})

      {:ok, count}
    end
  end

  defp parse_before(args) do
    case args do
      %{before: before} ->
        before = Base.decode64!(before)
        {"id", id} = :erlang.binary_to_term(before)
        id

      _ ->
        0
    end
  end

  defp parse_after(args) do
    case args do
      %{after: after_cursor} ->
        after_cursor = Base.decode64!(after_cursor)
        {"id", id} = :erlang.binary_to_term(after_cursor)
        id

      _ ->
        :infinity
    end
  end

  def between_cursors?(%{id: id}, before_cursor, after_cursor) do
    before_cursor < id and id < after_cursor
  end

  def collection_callback(items, _parent, _args) do
    OpenTelemetry.Tracer.with_span "RelayWithoutFuss.Schema.Relay.collection_callback/3" do
      count = Enum.count(items)
      OpenTelemetry.Tracer.set_attributes(%{count: count})

      result = %{nodes: items, total_count: count}
      {:ok, result}
    end
  end

  def connection_callback(items, _parent, args) do
    OpenTelemetry.Tracer.with_span "RelayWithoutFuss.Schema.Relay.connection_callback/3" do
      before_cursor = parse_before(args)
      after_cursor = parse_after(args)

      items_after_cursor =
        Enum.filter(items, fn i -> between_cursors?(i, before_cursor, after_cursor) end)

      case args do
        %{first: first} ->
          after_items =
            Enum.take(items_after_cursor, first)
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

          OpenTelemetry.Tracer.set_attributes(%{
            has_next_page: has_next_page,
            has_previous_page: has_previous_page,
            start_cursor: start_cursor,
            end_cursor: end_cursor
          })

          {:ok,
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
           }}
      end
    end
  end
end
