defmodule Report.Repo.Migrations.CreateEmployeesTable do
  use Ecto.Migration

  def change do
    create table(:employees, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :position, :string, null: false
      add :status, :string, null: false
      add :employee_type, :string, null: false
      add :is_active, :boolean, default: false, null: false
      add :inserted_by, :uuid, null: false
      add :updated_by, :uuid, null: false
      add :start_date, :date, null: false
      add :end_date, :date
      add :status_reason, :string
      add :legal_entity_id, :uuid
      add :division_id, :uuid
      add :party_id, :uuid

      timestamps(type: :utc_datetime)
    end

    create index(:employees, [:legal_entity_id])
    create index(:employees, [:division_id])
    create index(:employees, [:party_id])
  end
end
