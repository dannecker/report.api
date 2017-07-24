defmodule Report.Stats.MainStatsValidator do
  @moduledoc false

  import Ecto.Changeset

  alias Report.Stats.MainStatsRequest
  alias Report.Stats.RegionsStatsRequest
  alias Report.Stats.HistogramStatsRequest

  @fields_main_stats ~w(from_date to_date)a
  @fields_required_main_stats ~w(from_date to_date)a

  @fields_regions_stats ~w(from_date to_date region_id)a
  @fields_required_regions_stats ~w(from_date to_date)a

  @fields_histogram_stats ~w(from_date to_date region_id interval)a
  @fields_required_histogram_stats ~w(from_date to_date)a

  def main_stats_changeset(%MainStatsRequest{} = main_stats_request, params) do
    main_stats_request
    |> cast(params, @fields_main_stats)
    |> validate_required(@fields_required_main_stats)
    |> validate_period()
  end

  def regions_stats_changeset(%RegionsStatsRequest{} = regions_stats_request, params) do
    regions_stats_request
    |> cast(params, @fields_regions_stats)
    |> validate_required(@fields_required_regions_stats)
    |> validate_period()
  end

  def histogram_stats_changeset(%HistogramStatsRequest{} = histogram_stats_request, params) do
    histogram_stats_request
    |> cast(params, @fields_histogram_stats)
    |> validate_required(@fields_required_histogram_stats)
    |> validate_inclusion(:interval, Enum.map(~w(day month year)a, &HistogramStatsRequest.interval/1))
    |> validate_period()
  end

  defp validate_period(%Ecto.Changeset{valid?: true} = changeset) do
    from_date = get_change(changeset, :from_date)
    to_date = get_change(changeset, :to_date)
    case Date.compare(from_date, to_date) do
      :gt -> add_error(changeset, :to_date, "can't be less than from_date")
      _ -> changeset
    end
  end
  defp validate_period(changeset), do: changeset
end
