defmodule Report.Repo.Migrations.CreateDoctorsTable do
  use Ecto.Migration

  def change do
    create table(:employee_doctors, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :educations, :map, null: false
      add :qualifications, :map
      add :specialities, :map, null: false
      add :science_degree, :map
      add :employee_id, :uuid

      timestamps()
    end

    create index(:employee_doctors, [:employee_id])
  end
end
