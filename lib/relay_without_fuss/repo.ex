defmodule RelayWithoutFuss.Repo do
  use Ecto.Repo,
    otp_app: :relay_without_fuss,
    adapter: Ecto.Adapters.Postgres
end
