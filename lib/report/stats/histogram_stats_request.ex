defmodule Report.Stats.HistogramStatsRequest do
  @moduledoc false

  use Ecto.Schema

  @primary_key false

  @interval_day "DAY"
  @interval_month "MONTH"
  @interval_year "YEAR"

  schema "histogram_stats" do
    field :from_date, :date
    field :to_date, :date
    field :interval, :string
  end

  def interval(:day), do: @interval_day
  def interval(:month), do: @interval_month
  def interval(:year), do: @interval_year
end
