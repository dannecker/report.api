defmodule Report.Repo.Migrations.CreateStreetsTable do
  use Ecto.Migration

  def change do
    create table(:streets, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :district_id, references(:districts, type: :uuid, on_delete: :nothing)
      add :region_id, references(:regions, type: :uuid, on_delete: :nothing)
      add :settlement_id, references(:settlements, type: :uuid, on_delete: :nothing)
      add :street_type, :string
      add :street_name, :string
      add :street_number, :string
      add :postal_code, :string
      add :numbers, :map
      timestamps()
    end
  end
end
