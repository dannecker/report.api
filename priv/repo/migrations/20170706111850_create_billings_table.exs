defmodule Report.Repo.Migrations.CreateBillingsTable do
  use Ecto.Migration

  def change do
    create table(:billings, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :declaration_id, references(:declarations, type: :uuid, on_delete: :nothing)
      add :legal_entity_id, references(:legal_entities, type: :uuid, on_delete: :nothing)
      add :mountain_group, :string
      add :age_group, :string
      timestamps(type: :utc_datetime)
    end
  end
end
