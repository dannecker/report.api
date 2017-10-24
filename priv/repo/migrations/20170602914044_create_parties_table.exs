defmodule Report.Repo.Migrations.CreatePartiesTable do
  use Ecto.Migration

  def change do
    create table(:parties, primary_key: false) do
      add :id, :uuid, primary_key: true
    end
  end
end
