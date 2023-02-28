import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :relay_without_fuss, RelayWithoutFuss.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "relay_without_fuss_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :relay_without_fuss, RelayWithoutFussWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "gvR9FV4KeduFYsTFI8KkXZa7BYP8EGEsHFDbEqsiEiBHU6thRiNq6NI55PlVPTAd",
  server: false

# In test we don't send emails.
config :relay_without_fuss, RelayWithoutFuss.Mailer, adapter: Swoosh.Adapters.Test

# Print only warnings and errors during test
config :logger, level: :warn

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
