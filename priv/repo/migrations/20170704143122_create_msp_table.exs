defmodule Report.Repo.Migrations.CreateMspTable do
  use Ecto.Migration

  def change do
    create table(:medical_service_providers, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :accreditation, :map, null: true
      add :licenses, :map, null: true
      add :legal_entity_id, :uuid
      timestamps(type: :utc_datetime)
    end

    create index(:medical_service_providers, [:legal_entity_id])
  end
end
