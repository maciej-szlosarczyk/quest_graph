defmodule QuestGraph.Schema.Pagination.Edge do
  defstruct [:cursor, :node]

  alias QuestGraph.Schema.Cursor

  @type t() :: %__MODULE__{cursor: Cursor.t(), node: %{id: term()}}

  @spec encode(%{:id => term()}) :: t()
  def encode(item), do: %__MODULE__{cursor: Cursor.encode(item), node: item}
end
