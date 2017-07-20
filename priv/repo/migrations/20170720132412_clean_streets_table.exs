defmodule Report.Repo.Migrations.CleanStreetsTable do
  use Ecto.Migration

  def change do
    rename table(:streets), :street_type, to: :type
    rename table(:streets), :street_name, to: :name
    alter table(:streets) do
      remove :district_id
      remove :region_id
      remove :numbers
      remove :postal_code
    end
  end
end
