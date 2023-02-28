defmodule RelayWithoutFuss.Resource do
  alias RelayWithoutFuss.Quest

  use Ecto.Schema

  schema "resources" do
    belongs_to :quest, Quest

    field :name, :string
    timestamps(type: :utc_datetime)
  end
end
