defmodule QuestGraph.Program do
  alias QuestGraph.Quest

  use Ecto.Schema

  schema "programs" do
    has_many :quests, Quest

    field :name, :string
    timestamps(type: :utc_datetime)
  end
end
