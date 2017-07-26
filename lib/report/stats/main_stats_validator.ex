defmodule Report.Stats.MainStatsValidator do
  @moduledoc false

  import Ecto.Changeset

  alias Report.Stats.HistogramStatsRequest

  @fields_histogram_stats ~w(from_date to_date interval)a
  @fields_required_histogram_stats ~w(from_date to_date interval)a

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
    interval = get_change(changeset, :interval)

    with {:ok, changeset} <- compare_dates(changeset, from_date, to_date),
         {:ok, changeset} <- validate_date(changeset, from_date, interval, :start),
         {:ok, changeset} <- validate_date(changeset, to_date, interval, :end)
    do
      changeset
    end
  end
  defp validate_period(changeset), do: changeset

  defp compare_dates(changeset, from_date, to_date) do
    case Date.compare(from_date, to_date) do
      :gt -> add_error(changeset, :to_date, "can't be less than from_date")
      _ -> {:ok, changeset}
    end
  end

  defp validate_date(changeset, _, "DAY", _), do: {:ok, changeset}
  defp validate_date(changeset, date, "MONTH", :start) do
    case Timex.compare(Timex.beginning_of_month(date), date) do
      0 -> {:ok, changeset}
      _ -> add_error(changeset, :from_date, "invalid period")
    end
  end
  defp validate_date(changeset, date, "MONTH", :end) do
    case Timex.compare(Timex.end_of_month(date), date) do
      0 -> {:ok, changeset}
      _ -> add_error(changeset, :from_date, "invalid period")
    end
  end
  defp validate_date(changeset, date, "YEAR", :start) do
    case Timex.compare(Timex.beginning_of_year(date), date) do
      0 -> {:ok, changeset}
      false -> add_error(changeset, :from_date, "invalid period")
    end
  end
  defp validate_date(changeset, date, "YEAR", :end) do
    case Timex.compare(Timex.end_of_year(date), date) do
      0 -> {:ok, changeset}
      false -> add_error(changeset, :from_date, "invalid period")
    end
  end
end
