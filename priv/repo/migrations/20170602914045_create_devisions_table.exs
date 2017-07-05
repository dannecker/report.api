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
      add :legal_entity_id, references(:legal_entities, type: :uuid, on_delete: :nothing)
      add :location, :geometry
      timestamps()
    end
  end
end
