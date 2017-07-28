defmodule Report.Stats.MainStats do
  @moduledoc false

  alias Report.Repo
  alias Report.Replica.Declaration
  alias Report.Replica.DeclarationStatusHistory
  alias Report.Replica.Division
  alias Report.Replica.Employee
  alias Report.Replica.LegalEntity
  alias Report.Replica.Region
  alias Report.Stats.HistogramStatsRequest

  import Ecto.Changeset, only: [apply_changes: 1]
  import Ecto.Query
  import Report.Replica.Replicas
  import Report.Stats.MainStatsValidator

  use Timex

  def get_main_stats do
    msps =
      LegalEntity
      |> params_query(legal_entity_params())
      |> count_query()

    doctors =
      Employee
      |> params_query(doctor_params())
      |> count_query()

    declarations =
      Declaration
      |> params_query(%{"status" => "active"})
      |> count_query()

    {:ok, %{
      "declarations" => declarations,
      "doctors" => doctors,
      "msps" => msps,
    }}
  end

  def get_division_stats(id) do
    division = Repo.get!(Division, id)

    msps =
      LegalEntity
      |> params_query(legal_entity_params())
      |> join(:left, [le], d in Division, d.legal_entity_id == le.id)
      |> where([le, d], d.id == ^id)
      |> count_query()

    doctors =
      Employee
      |> params_query(Map.merge(doctor_params(), %{"division_id" => id}))
      |> count_query()

    declarations =
      Declaration
      |> params_query(%{"division_id" => id, "status" => "active"})
      |> count_query()

    {:ok, %{
      "division" => division,
      "stats" => %{
        "declarations" => declarations,
        "msps" => msps,
        "doctors" => doctors,
      }
    }}
  end

  def get_regions_stats(id) do
    region = Repo.get!(Region, id)

    param = [%{"type" => "REGISTRATION", "area" => region.name}]
    msps =
      LegalEntity
      |> params_query(legal_entity_params())
      |> where([le], fragment("? @> ?", le.addresses, ^param))
      |> count_query()

    doctors =
      Employee
      |> params_query(doctor_params())
      |> join(:left, [e], le in assoc(e, :legal_entity))
      |> where([e, le], fragment("? @> ?", le.addresses, ^param))
      |> count_query()

    declarations =
      Declaration
      |> params_query(%{"status" => "active"})
      |> join(:left, [d], dv in assoc(d, :division))
      |> where([d, dv], fragment("? @> ?", dv.addresses, ^param))
      |> count_query()

    {:ok, %{
      "region" => region,
      "stats" => %{
        "declarations" => declarations,
        "doctors" => doctors,
        "msps" => msps
      }
    }}
  end

  def get_histogram_stats(params) do
    with %Ecto.Changeset{valid?: true} = changeset <- histogram_stats_changeset(%HistogramStatsRequest{}, params),
         histogram_stats_request <- apply_changes(changeset),
         skeleton <- histogram_stats_skeleton(histogram_stats_request),
         skeleton <- histogram_stats_by_periods(histogram_stats_request, skeleton)
    do
      {:ok, skeleton}
    end
  end

  defp histogram_stats_by_periods(%HistogramStatsRequest{} = histogram_stats_request, skeleton) do
    %{from_date: from_date, to_date: to_date, interval: interval} = histogram_stats_request

    active_declarations = active_declarations_by_date(from_date)
    created_declarations =
      Declaration
      |> interval_query(from_date, to_date)
      |> declarations_by_intervals(interval)
      |> Repo.all
      |> Enum.into(%{}, fn %{count: count, date: date} ->
        {date, count}
      end)
    closed_declarations =
      DeclarationStatusHistory
      |> interval_query(from_date, to_date)
      |> where([dsh], dsh.status in ~w(terminated closed))
      |> declarations_by_intervals(interval)
      |> Repo.all
      |> Enum.into(%{}, fn %{count: count, date: date} ->
        {date, count}
      end)

    head = Map.put(hd(skeleton), "declarations_active_start", active_declarations)
    skeleton = [head | List.delete_at(skeleton, 0)]

    {skeleton, _} =
      skeleton
      |> Enum.with_index
      |> Enum.reduce({skeleton, nil}, fn {%{"period_name" => date} = value, i}, {acc, previous} ->
        active_start = if is_nil(previous),
          do: Map.get(value, "declarations_active_start"),
          else: Map.get(previous, "declarations_active_end")

        created = Map.get(created_declarations, date, 0)
        closed = Map.get(closed_declarations, date, 0)
        new_value = %{value |
          "declarations_created" => created,
          "declarations_closed" => closed,
          "declarations_active_start" => active_start,
          "declarations_active_end" => active_start + created - closed}
        {List.replace_at(acc, i, new_value), new_value}
      end)
    skeleton
  end

  defp declarations_by_intervals(query, "DAY"), do: histogram_day_query(query)
  defp declarations_by_intervals(query, "MONTH"), do: histogram_month_query(query)
  defp declarations_by_intervals(query, "YEAR"), do: histogram_year_query(query)

  def histogram_stats_skeleton(%HistogramStatsRequest{} = request) do
    %{interval: interval, from_date: from_date, to_date: to_date} = request
    intervals = Interval.new(
      from: from_date,
      until: to_date,
      right_open: false,
      step: interval_step(interval)
    )
    Enum.map(intervals, fn date ->
      %{
        "period_type" => interval,
        "period_name" => format_date(date, interval),
        "declarations_created" => 0,
        "declarations_closed" => 0,
        "declarations_active_start" => 0,
        "declarations_active_end" => 0,
      }
    end)
  end

  defp active_declarations_by_date(date) do
    DeclarationStatusHistory
    |> lt_date_query(date)
    |> join(:left, [dsh], d in assoc(dsh, :declaration))
    |> select([dsh, d], %{
      status: dsh.status,
      declaration_id: dsh.declaration_id,
      x: fragment("""
      rank() OVER (
        PARTITION BY ?
        ORDER BY ? DESC
      )
      """, dsh.declaration_id, dsh.inserted_at)
    })
    |> subquery()
    |> where([a], a.x == 1)
    |> params_query(%{"status" => "active"})
    |> select([a], count(a.declaration_id))
    |> Repo.one!
  end

  defp doctor_params do
    %{"employee_type" => "DOCTOR", "status" => "APPROVED", "is_active" => true}
  end

  defp legal_entity_params, do: %{"is_active" => true}

  defp get_interval_to_date(date, "DAY"), do: date
  defp get_interval_to_date(date, "MONTH") do
    date
    |> Timex.end_of_month()
    |> get_interval_to_date(HistogramStatsRequest.interval(:day))
  end
  defp get_interval_to_date(date, "YEAR") do
    date
    |> Timex.end_of_year()
    |> get_interval_to_date(HistogramStatsRequest.interval(:day))
  end

  defp format_date(date), do: format_date(date, HistogramStatsRequest.interval(:day))
  defp format_date(date, "DAY"), do: Timex.format!(date, "%F", :strftime)
  defp format_date(date, "MONTH"), do: Timex.format!(date, "%Y-%m", :strftime)
  defp format_date(date, "YEAR"), do: Timex.format!(date, "%Y", :strftime)

  defp histogram_day_query(query) do
    query
    |> group_by([a], fragment("to_char(?, 'YYYY-MM-DD')", a.inserted_at))
    |> select([a], %{
      count: count(a.inserted_at),
      date: fragment("to_char(?, 'YYYY-MM-DD')", a.inserted_at)
    })
  end

  defp histogram_month_query(query) do
    query
    |> group_by([a], fragment("to_char(?, 'YYYY-MM')", a.inserted_at))
    |> select([a], %{
      count: count(a.inserted_at),
      date: fragment("to_char(?, 'YYYY-MM')", a.inserted_at)
    })
  end

  defp histogram_year_query(query) do
    query
    |> group_by([a], fragment("to_char(?, 'YYYY')", a.inserted_at))
    |> select([a], %{
      count: count(a.inserted_at),
      date: fragment("to_char(?, 'YYYY')", a.inserted_at)
    })
  end

  defp interval_step("DAY"), do: [days: 1]
  defp interval_step("MONTH"), do: [months: 1]
  defp interval_step("YEAR"), do: [years: 1]
end
