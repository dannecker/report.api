defmodule Report.Repo.Migrations.AddIsValidToBilling do
  use Ecto.Migration

  def change do
    alter table(:billings) do
      add :is_valid, :boolean, null: false, default: false
    end
  end
end
