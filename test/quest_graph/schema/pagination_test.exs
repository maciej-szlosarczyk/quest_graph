defmodule QuestGraph.Schema.PaginationTest do
  use QuestGraph.DataCase, async: true
  use ExUnitProperties

  alias QuestGraph.Schema.Cursor
  alias QuestGraph.Schema.Pagination

  describe "callback/3 with arguments" do
    setup [:attach_telemetry_handler]

    property "executes a telemetry event" do
      check all list <- StreamData.list_of(integer()) do
        list =
          list
          |> Enum.sort()
          |> Enum.map(fn x -> %{id: x} end)

        count = Enum.count(list)
        args = %{first: 10}
        Pagination.callback(list, nil, args)

        assert_receive {:telemetry_event,
                        %{
                          event: [:quest_graph, :pagination_callback, :start],
                          metadata: %{nodes: ^list, args: %{}, parent: nil}
                        }}

        assert_receive {:telemetry_event,
                        %{
                          event: [:quest_graph, :pagination_callback, :stop],
                          metadata: %{edges_count: ^count}
                        }}
      end
    end

    test "%{} args" do
      list = [1] |> Enum.map(fn x -> %{id: x} end)
      args = %{}
      result = Pagination.callback(list, nil, args)

      expected_result = %Pagination{
        __all_edges__: list,
        edges: [%{cursor: Cursor.encode(%{id: 1}), node: %{id: 1}}],
        edges_count: 1,
        page_info: %QuestGraph.Schema.Pagination.PageInfo{
          has_previous_page: false,
          has_next_page: false,
          start_cursor: Cursor.encode(%{id: 1}),
          end_cursor: Cursor.encode(%{id: 1})
        }
      }

      assert result == expected_result
    end

    test "%{first: 10, after: Cursor.encode(%{id: 5})} args" do
      limit = 10
      cursor = Cursor.encode(%{id: 5})
      list = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] |> Enum.map(fn x -> %{id: x} end)
      args = %{first: limit, after: cursor}
      result = Pagination.callback(list, nil, args)

      expected_result = %Pagination{
        __all_edges__: list,
        edges: [
          %{cursor: Cursor.encode(%{id: 6}), node: %{id: 6}},
          %{cursor: Cursor.encode(%{id: 7}), node: %{id: 7}},
          %{cursor: Cursor.encode(%{id: 8}), node: %{id: 8}},
          %{cursor: Cursor.encode(%{id: 9}), node: %{id: 9}},
          %{cursor: Cursor.encode(%{id: 10}), node: %{id: 10}},
          %{cursor: Cursor.encode(%{id: 11}), node: %{id: 11}},
          %{cursor: Cursor.encode(%{id: 12}), node: %{id: 12}},
          %{cursor: Cursor.encode(%{id: 13}), node: %{id: 13}},
          %{cursor: Cursor.encode(%{id: 14}), node: %{id: 14}},
          %{cursor: Cursor.encode(%{id: 15}), node: %{id: 15}}
        ],
        edges_count: 15,
        page_info: %QuestGraph.Schema.Pagination.PageInfo{
          has_previous_page: true,
          has_next_page: false,
          start_cursor: Cursor.encode(%{id: 6}),
          end_cursor: Cursor.encode(%{id: 15})
        }
      }

      assert result == expected_result
    end

    test "%{last: 2, after: Cursor.encode(%{id: 5})} args" do
      limit = 2
      cursor = Cursor.encode(%{id: 5})
      list = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] |> Enum.map(fn x -> %{id: x} end)
      args = %{last: limit, after: cursor}
      result = Pagination.callback(list, nil, args)

      expected_result = %Pagination{
        __all_edges__: list,
        edges: [
          %{cursor: Cursor.encode(%{id: 14}), node: %{id: 14}},
          %{cursor: Cursor.encode(%{id: 15}), node: %{id: 15}}
        ],
        edges_count: 15,
        page_info: %QuestGraph.Schema.Pagination.PageInfo{
          has_previous_page: true,
          has_next_page: false,
          start_cursor: Cursor.encode(%{id: 14}),
          end_cursor: Cursor.encode(%{id: 15})
        }
      }

      assert result == expected_result
    end
  end

  describe "callback/3 with no args" do
    setup [:attach_telemetry_handler]

    property "executes a telemetry event" do
      check all list <- StreamData.list_of(integer()) do
        list =
          list
          |> Enum.sort()
          |> Enum.map(fn x -> %{id: x} end)

        count = Enum.count(list)
        Pagination.callback(list, nil, %{})

        assert_receive {:telemetry_event,
                        %{
                          event: [:quest_graph, :pagination_callback, :start],
                          metadata: %{nodes: ^list, args: %{}, parent: nil}
                        }}

        assert_receive {:telemetry_event,
                        %{
                          event: [:quest_graph, :pagination_callback, :stop],
                          metadata: %{edges_count: ^count}
                        }}
      end
    end

    test "handles empty list properly" do
      count = 0
      result = Pagination.callback([], nil, %{})

      expected_result = %Pagination{
        page_info: %QuestGraph.Schema.Pagination.PageInfo{
          has_previous_page: false,
          has_next_page: false,
          start_cursor: nil,
          end_cursor: nil
        },
        edges: [],
        __all_edges__: [],
        edges_count: count
      }

      assert result == expected_result
    end

    property "returns a map with relay keys" do
      check all list <- StreamData.list_of(integer(), min_length: 1) do
        list =
          list
          |> Enum.sort()
          |> Enum.map(fn x -> %{id: x} end)

        count = Enum.count(list)
        result = Pagination.callback(list, nil, %{})

        edges = for edge <- list, do: %{node: edge, cursor: Cursor.encode(edge)}

        start_cursor = Enum.at(list, 0) |> Cursor.encode()
        end_cursor = Enum.at(list, -1) |> Cursor.encode()

        expected_result = %Pagination{
          page_info: %QuestGraph.Schema.Pagination.PageInfo{
            has_previous_page: false,
            has_next_page: false,
            start_cursor: start_cursor,
            end_cursor: end_cursor
          },
          edges: edges,
          __all_edges__: list,
          edges_count: count
        }

        assert result == expected_result
      end
    end
  end

  def attach_telemetry_handler(context) do
    ref = make_ref()
    test_ref = {context.case, context.test, ref}

    events = [
      [:quest_graph, :pagination_callback, :start],
      [:quest_graph, :pagination_callback, :stop],
      [:quest_graph, :pagination_callback, :exception]
    ]

    send_function =
      &Kernel.send(
        self(),
        {:telemetry_event, %{event: &1, measurements: &2, metadata: &3, config: &4}}
      )

    :telemetry.attach_many(test_ref, events, send_function, nil)
    on_exit(fn -> :telemetry.detach(test_ref) end)
  end
end
