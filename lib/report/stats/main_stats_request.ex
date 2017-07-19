defmodule Report.Stats.MainStatsRequest do
  @moduledoc false

  use Ecto.Schema

  @primary_key false

  schema "main_stats" do
    field :from_date, :date
    field :to_date, :date
  end
end
