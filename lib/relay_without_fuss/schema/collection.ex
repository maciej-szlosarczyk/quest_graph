defmodule RelayWithoutFuss.Schema.Collection do
  require OpenTelemetry.Tracer

  @doc """
  A to use with dataloaded collections that returns the items as well as their total count.

  ## Example usage

      field :resources, :resource_collection do
        resolve dataloader(Repo, :resources, callback: &Collection.callback/3)
      end
  """
  def callback(items, _parent, _args) do
    OpenTelemetry.Tracer.with_span "#{__MODULE__}.callback/3" do
      count = Enum.count(items)
      OpenTelemetry.Tracer.set_attributes(%{count: count})

      result = %{nodes: items, total_count: count}
      {:ok, result}
    end
  end
end
