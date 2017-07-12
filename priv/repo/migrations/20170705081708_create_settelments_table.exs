defmodule Report.Repo.Migrations.CreateSettelmentsTable do
  use Ecto.Migration

  def change do
    create table(:settlements, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :district_id, :uuid, null: true
      add :region_id, :uuid, null: false
      add :koatuu, :string, size: 10
      add :name, :string, null: false
      add :mountain_group, :string, null: true
      add :type, :string, size: 50
      add :parent_settlement_id, :uuid
      timestamps(type: :utc_datetime)
    end
  end
end
