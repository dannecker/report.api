defmodule Report.Repo.Migrations.ChangeBillingsMountainGroup do
  use Ecto.Migration

  def change do
    execute "alter table billings alter column mountain_group type boolean using mountain_group::boolean;"
  end
end
