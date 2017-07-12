defmodule Report.Repo.Migrations.CreatePersonsTable do
  use Ecto.Migration

  def change do
    create table(:persons, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :birth_date, :date
      add :death_date, :date
      add :addresses, :map
      timestamps(type: :utc_datetime)
    end
  end
end
