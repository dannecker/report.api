defmodule Report.Repo.Migrations.CreateMedicalProgramsTable do
  use Ecto.Migration

  def change do
    create table(:medical_programs, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name, :string, null: false
      add :is_active, :boolean, null: false
      add :inserted_by, :uuid, null: false
      add :updated_by, :uuid, null: false

      timestamps()
    end
  end
end
