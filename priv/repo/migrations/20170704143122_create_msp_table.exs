defmodule Report.Repo.Migrations.CreateMspTable do
  use Ecto.Migration

  def change do
    create table(:medical_service_providers, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :accreditation, :map, null: true
      add :licenses, :map
      add :legal_entity_id, references(:legal_entities, type: :uuid, on_delete: :nothing)
      timestamps(type: :utc_datetime)
    end
  end
end
