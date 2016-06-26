use Mix.Config

config :kerosene, Kerosene.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "kerosene_dev",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox