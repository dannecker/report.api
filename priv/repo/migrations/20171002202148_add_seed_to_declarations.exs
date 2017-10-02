defmodule Report.Repo.Migrations.AddSeedToDeclarations do
  use Ecto.Migration

  def change do
    alter table(:declarations) do
      add :seed, :string
    end
  end
end
