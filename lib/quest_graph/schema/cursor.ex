defmodule QuestGraph.Schema.Cursor do
  @spec encode(term()) :: String.t()
  @type t() :: String.t()

  def encode(%{id: id}) do
    "id:#{id}"
    |> Base.encode64(padding: false)
  end

  def decode(cursor) do
    binary = Base.decode64!(cursor, padding: false)

    case binary do
      "id:" <> id ->
        {id, ""} = Integer.parse(id)
        id
    end
  end
end
