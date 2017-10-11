defmodule Report.Repo.Migrations.IncreaseEdMspsTerritoriesBuildings do
  use Ecto.Migration

  def change do
    alter table(:red_msps_territories) do
      modify :buildings, :text
    end
  end
end
