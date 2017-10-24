defmodule Report.Repo.Migrations.RemovePartyColumns do
  use Ecto.Migration

  def change do
    alter table(:parties) do
      add :first_name, :string, null: false
      add :second_name, :string
      add :last_name, :string, null: false
      timestamps()
    end
  end
end
