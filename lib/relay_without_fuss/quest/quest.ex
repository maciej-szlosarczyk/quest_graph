defmodule RelayWithoutFuss.Quest do
  alias RelayWithoutFuss.Program
  alias RelayWithoutFuss.Resource

  use Ecto.Schema

  schema "quests" do
    has_many :resources, Resource
    belongs_to :program, Program

    field :name, :string
    timestamps(type: :utc_datetime)
  end
end
