defmodule RelayWithoutFuss.Program do
  alias RelayWithoutFuss.Quest

  use Ecto.Schema

  schema "programs" do
    has_many :quests, Quest

    field :name, :string
    timestamps(type: :utc_datetime)
  end
end
