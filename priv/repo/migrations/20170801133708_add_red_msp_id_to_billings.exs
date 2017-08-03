defmodule Report.Repo.Migrations.AddRedMspIdToBillings do
  use Ecto.Migration

  def change do
    alter table(:billings) do
      add :red_msp_id, references(:red_msps, type: :uuid), null: true
    end
  end
end
