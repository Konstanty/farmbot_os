# Mix.Tasks.Ecto.Drop.run([])
# Mix.Tasks.Ecto.Migrate.run([])

# Ecto.Adapters.SQL.Sandbox.mode(Farmbot.Config.Repo, :auto)
# Ecto.Adapters.SQL.Sandbox.mode(Farmbot.Logger.Repo, {:shared, self()})
# Ecto.Adapters.SQL.Sandbox.mode(Farmbot.Asset.Repo,  :auto)
tz = System.get_env("TZ") || Timex.local().time_zone

FarmbotCore.Asset.Device.changeset(FarmbotCore.Asset.device(), %{timezone: tz})
|> FarmbotCore.Asset.Repo.insert_or_update!()

ExUnit.start()
