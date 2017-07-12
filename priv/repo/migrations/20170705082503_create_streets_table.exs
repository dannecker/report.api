defmodule Report.Repo.Migrations.CreateStreetsTable do
  use Ecto.Migration

  def change do
    create table(:streets, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :district_id, :uuid
      add :region_id, :uuid
      add :settlement_id, :uuid
      add :street_type, :string
      add :street_name, :string
      add :street_number, :string
      add :postal_code, :string
      add :numbers, :map
      timestamps(type: :utc_datetime)
    end
  end
end
