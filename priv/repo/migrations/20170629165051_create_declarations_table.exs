defmodule Report.Repo.Migrations.CreateDeclarationsTable do
  use Ecto.Migration

  def change do
    create table(:declarations, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :declaration_signed_id, :uuid, null: false
      add :employee_id, references(:employees, type: :uuid, on_delete: :nothing)
      add :person_id, references(:persons, type: :uuid, on_delete: :nothing)
      add :start_date, :utc_datetime, null: false
      add :end_date, :utc_datetime, null: false
      add :status, :string, null: false
      add :signed_at, :utc_datetime, null: false
      add :created_by, :uuid, null: false
      add :updated_by, :uuid, null: false
      add :is_active, :boolean, default: false
      add :scope, :string, null: false
      add :division_id, :uuid, null: false
      add :legal_entity_id, :uuid, null: false

      timestamps([type: :utc_datetime])
    end
  end
end
