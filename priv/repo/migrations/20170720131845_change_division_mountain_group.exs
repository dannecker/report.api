defmodule Report.Repo.Migrations.ChangeDivisionMountainGroup do
  use Ecto.Migration

  def change do
    execute "alter table divisions alter column mountain_group type boolean using mountain_group::boolean;"
    execute "alter table settlements alter column mountain_group type boolean using mountain_group::boolean;"
  end
end
