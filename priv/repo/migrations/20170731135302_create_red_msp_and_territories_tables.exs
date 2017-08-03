defmodule Report.Repo.Migrations.AddRedMspAndTerritoriesTables do
  use Ecto.Migration

  def change do
    create table(:red_msps, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name, :string, null: false
      add :edrpou, :string, null: false
      add :is_active, :boolean, null: false, default: true
      add :type, :string, null: false
      add :population_count, :integer, null: false
      timestamps(type: :utc_datetime)
    end
    create unique_index(:red_msps, [:edrpou])

    create table(:red_msps_territories, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :red_msp_id, references(:red_msps, type: :uuid), null: false
      add :settlement_id, :uuid, null: false
      add :street_type, :string
      add :street_name, :string
      add :postal_code, :string, length: 5
      add :buildings, :string, length: 2000
      timestamps(type: :utc_datetime)
    end
  end
end
