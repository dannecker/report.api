defmodule Report.Repo.Migrations.CreateStreetAliasesTable do
  use Ecto.Migration

  def change do
    create table(:streets_aliases, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :street_id, references(:streets, type: :uuid, on_delete: :nothing), null: true
      add :name, :string, null: false
    end
  end
end
