defmodule Report.Stats.RegionsStatsRequest do
  @moduledoc false

  use Ecto.Schema

  @primary_key false

  schema "regions_stats" do
    field :from_date, :date
    field :to_date, :date
    field :region_id, :string
  end
end
