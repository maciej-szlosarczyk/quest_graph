defmodule QuestGraph.Schema.Collection do
  @doc """
  A to use with dataloaded collections that returns the items as well as their total count.

  ## Example usage

      field :resources, :resource_collection do
        resolve dataloader(Repo, :resources, callback: &Collection.callback/3)
      end
  """
  @spec callback([any], any, any) :: {:ok, false}
  def callback(nodes, parent, args) do
    metadata = %{nodes: nodes, parent: parent, args: args}

    :telemetry.span([:quest_graph, :collection_callback], metadata, fn ->
      total_count = Enum.count(nodes)
      result = %{nodes: nodes, total_count: total_count}
      {{:ok, result}, %{total_count: total_count}}
    end)
  end
end
