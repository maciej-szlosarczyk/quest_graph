defmodule QuestGraph.Schema.CollectionTest do
  use QuestGraph.DataCase, async: true
  use ExUnitProperties

  alias QuestGraph.Schema.Collection

  describe "callback/3" do
    setup [:attach_telemetry_handler]

    property "executes a telemetry event" do
      check all list <- StreamData.list_of(integer()) do
        count = Enum.count(list)
        Collection.callback(list, nil, %{})

        assert_receive {:telemetry_event,
                        %{
                          event: [:quest_graph, :collection_callback, :start],
                          metadata: %{nodes: ^list, args: %{}, parent: nil}
                        }}

        assert_receive {:telemetry_event,
                        %{
                          event: [:quest_graph, :collection_callback, :stop],
                          metadata: %{total_count: ^count}
                        }}
      end
    end

    property "returns a map with the count of items" do
      check all list <- StreamData.list_of(integer()) do
        count = Enum.count(list)
        result = Collection.callback(list, nil, %{})

        assert result == {:ok, %{total_count: count, nodes: list}}
      end
    end
  end

  def attach_telemetry_handler(context) do
    ref = make_ref()
    test_ref = {context.case, context.test, ref}

    events = [
      [:quest_graph, :collection_callback, :start],
      [:quest_graph, :collection_callback, :stop],
      [:quest_graph, :collection_callback, :exception]
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
