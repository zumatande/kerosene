Kerosene.Repo.start_link()
ExUnit.start()

Mix.Task.run "ecto.create", ~w(-r Kerosene.Repo)
Mix.Task.run "ecto.migrate", ~w(-r Kerosene.Repo)
Ecto.Adapters.SQL.Sandbox.mode(Kerosene.Repo, :manual)