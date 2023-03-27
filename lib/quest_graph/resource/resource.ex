defmodule QuestGraph.Resource do
  alias QuestGraph.Quest

  use Ecto.Schema

  schema "resources" do
    belongs_to :quest, Quest

    field :name, :string
    timestamps(type: :utc_datetime)
  end
end
