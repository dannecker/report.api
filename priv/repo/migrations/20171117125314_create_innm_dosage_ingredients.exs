defmodule Report.Repo.Migrations.CreateInnmDosageIngredients do
  use Ecto.Migration

  def change do
    create table(:ingredients, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :dosage, :map, null: false
      add :is_primary, :boolean, default: false, null: false

      add :medication_child_id, references(:medications, type: :uuid, on_delete: :nothing), null: true
      add :innm_child_id, references(:innms, type: :uuid, on_delete: :nothing), null: true
      add :parent_id, references(:medications, type: :uuid, on_delete: :nothing), null: false

      timestamps(type: :utc_datetime)
    end
  end
end
