defmodule Report.Repo.Migrations.CreateRegionsTable do
  use Ecto.Migration

  def change do
    create table(:regions, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name, :string, size: 50, null: false
      add :koatuu, :string, size: 10
      timestamps(type: :utc_datetime)
    end

  end
end
