# Enable PostGIS for Ecto
Postgrex.Types.define(
  Report.PostgresTypes,
  [Geo.PostGIS.Extension] ++ Ecto.Adapters.Postgres.extensions(),
  json: Poison
)
