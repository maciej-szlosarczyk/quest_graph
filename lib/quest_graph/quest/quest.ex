defmodule QuestGraph.Quest do
  alias QuestGraph.Program
  alias QuestGraph.Resource

  use Ecto.Schema

  schema "quests" do
    has_many :resources, Resource
    belongs_to :program, Program

    field :name, :string
    timestamps(type: :utc_datetime)
  end
end
