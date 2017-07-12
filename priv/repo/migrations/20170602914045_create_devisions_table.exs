defmodule Report.Repo.Migrations.CreateDevisionsTable do
  use Ecto.Migration

  def change do
    create table(:divisions, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :external_id, :string
      add :name, :string, null: false
      add :type, :string, null: false
      add :mountain_group, :string
      add :addresses, :map, null: false
      add :phones, :map, null: false
      add :email, :string
      add :status, :string, null: false
      add :is_active, :boolean, default: false, null: false
      add :legal_entity_id, :uuid
      add :location, :geometry
      timestamps(type: :utc_datetime)
    end
    create index(:divisions, [:legal_entity_id])
  end
end
