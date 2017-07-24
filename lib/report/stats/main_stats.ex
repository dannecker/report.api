defmodule Report.Stats.MainStats do
  @moduledoc false

  alias Report.Repo
  alias Report.Replica.Declaration
  alias Report.Replica.DeclarationStatusHistory
  alias Report.Replica.Employee
  alias Report.Replica.LegalEntity
  alias Report.Replica.Region
  alias Report.Stats.MainStatsRequest
  alias Report.Stats.RegionsStatsRequest
  alias Report.Stats.HistogramStatsRequest

  import Ecto.Changeset, only: [apply_changes: 1]
  import Ecto.Query
  import Report.Replica.Replicas
  import Report.Stats.MainStatsValidator

  use Timex

  def get_main_stats(params) do
    with %Ecto.Changeset{valid?: true} = changeset <- main_stats_changeset(%MainStatsRequest{}, params),
         main_stats_request <- apply_changes(changeset),
         %{from_date: from_date, to_date: to_date} = main_stats_request
    do
      {:ok, %{
        "from_date" => to_string(from_date),
        "to_date" => to_string(to_date),
        "period" => main_stats_by_period(main_stats_request),
        "total" => main_stats_by_date(main_stats_request.to_date),
      }}
    else
      %Ecto.Changeset{valid?: false} = changeset -> {:error, changeset}
    end
  end

  def get_division_stats(id) do
    doctors =
      Employee
      |> params_query(Map.merge(doctor_params(), %{"division_id" => id}))
      |> count_query()

    total_declarations =
      Declaration
      |> params_query(%{"division_id" => id})
      |> count_query()

    created_declarations =
      Declaration
      |> params_query(%{"status" => "active", "division_id" => id})
      |> count_query()

    closed_declarations =
      Declaration
      |> params_query(%{"status" => "terminated", "division_id" => id})
      |> count_query()

    {:ok, %{
      "total" => %{
        "declarations_total" => total_declarations,
        "declarations_created" => created_declarations,
        "declarations_closed" => closed_declarations,
        "doctors" => doctors,
      }
    }}
  end

  def get_regions_stats(params) do
    with %Ecto.Changeset{valid?: true} = changeset <- regions_stats_changeset(%RegionsStatsRequest{}, params),
         regions_stats_request <- apply_changes(changeset),
         {:ok, regions} <- get_regions(regions_stats_request.region_id),
         skeleton <- region_stats_skeleton(regions),
         %{from_date: from_date, to_date: to_date} = regions_stats_request,
         skeleton <- regions_stats_by_period(regions_stats_request, regions, skeleton),
         skeleton <- regions_stats_by_date(regions_stats_request, regions, skeleton)
    do
      {:ok, %{
        "from_date" => to_string(from_date),
        "to_date" => to_string(to_date),
        "regions" => Map.values(skeleton),
      }}
    end
  end

  def get_histogram_stats(params) do
    with %Ecto.Changeset{valid?: true} = changeset <- histogram_stats_changeset(%HistogramStatsRequest{}, params),
         histogram_stats_request <- apply_changes(changeset),
         {:ok, regions} <- get_regions(histogram_stats_request.region_id),
         intervals <- histogram_intervals(histogram_stats_request),
         skeleton <- histogram_stats_skeleton(intervals, histogram_stats_request),
         skeleton <- histogram_stats_by_period(histogram_stats_request, regions, skeleton),
         skeleton <- histogram_stats_by_date(histogram_stats_request, regions, skeleton)
    do
      {:ok, Map.values(skeleton)}
    end
  end

  def main_stats_by_period(%MainStatsRequest{from_date: from_date, to_date: to_date}) do
    msps =
      LegalEntity
      |> params_query(legal_entity_params())
      |> interval_query(from_date, to_date)
      |> count_query()

    doctors =
      Employee
      |> params_query(doctor_params())
      |> interval_query(from_date, to_date)
      |> count_query()

    total_declarations =
      Declaration
      |> interval_query(from_date, to_date)
      |> count_query()

    created_declarations = declarations_by_period(from_date, to_date, "active")
    closed_declarations = declarations_by_period(from_date, to_date, "terminated")

    %{
      "declarations_total" => total_declarations,
      "declarations_created" => created_declarations,
      "declarations_closed" => closed_declarations,
      "msps" => msps,
      "doctors" => doctors,
    }
  end

  def main_stats_by_date(date) do
    msps =
      LegalEntity
      |> params_query(legal_entity_params())
      |> lte_date_query(date)
      |> count_query()

    doctors =
      Employee
      |> params_query(doctor_params())
      |> lte_date_query(date)
      |> count_query()
    # select count(*) from declarations where inserted_at <= to_date
    total_declarations =
      Declaration
      |> lte_date_query(date)
      |> count_query()

    # select count(*) from declarations where inserted_at <= to_date and status in ('active')
    created_declarations =
      Declaration
      |> params_query(%{"status" => "active"})
      |> lte_date_query(date)
      |> count_query()

    # select count(*) from declarations where inserted_at <= to_date
    # and status in ('terminated', 'closed')
    closed_declarations =
      Declaration
      |> params_query(%{"status" => "terminated"})
      |> lte_date_query(date)
      |> count_query()

    %{
      "declarations_total" => total_declarations,
      "declarations_created" => created_declarations,
      "declarations_closed" => closed_declarations,
      "msps" => msps,
      "doctors" => doctors,
    }
  end

  def regions_stats_by_period(%RegionsStatsRequest{from_date: from_date, to_date: to_date}, regions, skeleton) do
    region = if Enum.count(regions) == 1, do: regions |> List.first |> Map.get(:name), else: nil
    date_params = %{"from" => from_date, "to" => to_date}
    msps = msps_by_regions(date_params, region)
    doctors = doctors_by_regions(date_params, region)
    total_declarations = declarations_by_regions(date_params, region)
    created_declarations = declarations_by_regions_periods(date_params, region, "active")
    closed_declarations = declarations_by_regions_periods(date_params, region, "terminated")

    skeleton
    |> add_to_regions_skeleton(msps, ~w(period msps))
    |> add_to_regions_skeleton(doctors, ~w(period doctors))
    |> add_to_regions_skeleton(total_declarations, ~w(period declarations_total))
    |> add_to_regions_skeleton(created_declarations, ~w(period declarations_created))
    |> add_to_regions_skeleton(closed_declarations, ~w(period declarations_closed))
  end

  def regions_stats_by_date(%RegionsStatsRequest{to_date: date}, regions, skeleton) do
    region = if Enum.count(regions) == 1, do: regions |> List.first |> Map.get(:name), else: nil
    date_params = %{"to" => date}
    msps = msps_by_regions(date_params, region)
    doctors = doctors_by_regions(date_params, region)
    total_declarations = declarations_by_regions(date_params, region)
    created_declarations = declarations_by_regions(date_params, region, "active")
    closed_declarations = declarations_by_regions(date_params, region, "terminated")

    skeleton
    |> add_to_regions_skeleton(msps, ~w(total msps))
    |> add_to_regions_skeleton(doctors, ~w(total doctors))
    |> add_to_regions_skeleton(total_declarations, ~w(total declarations_total))
    |> add_to_regions_skeleton(created_declarations, ~w(total declarations_created))
    |> add_to_regions_skeleton(closed_declarations, ~w(total declarations_closed))
  end

  defp region_stats_skeleton(regions) do
    Enum.reduce(regions, %{}, fn %{id: id, name: name}, acc ->
      Map.put(acc, name, %{
        "region" => %{
          "id" => id,
          "name" => name
        },
        "period" => %{
          "msps" => 0,
          "doctors" => 0,
          "declarations_total" => 0,
          "declarations_created" => 0,
          "declarations_closed" => 0,
        },
        "total" => %{
          "msps" => 0,
          "doctors" => 0,
          "declarations_total" => 0,
          "declarations_created" => 0,
          "declarations_closed" => 0,
        }
      })
    end)
  end

  defp add_to_regions_skeleton(skeleton, values, keys) do
    Enum.reduce(values, skeleton, fn %{count: value, region: name}, acc ->
      put_in(acc, [name | keys], value)
    end)
  end

  def histogram_intervals(%HistogramStatsRequest{interval: interval, from_date: from_date, to_date: to_date}) do
    Interval.new(
      from: from_date,
      until: to_date,
      right_open: false,
      step: interval_step(interval)
    )
  end

  defp interval_step("DAY"), do: [days: 1]
  defp interval_step("MONTH"), do: [months: 1]
  defp interval_step("YEAR"), do: [years: 1]

  defp histogram_stats_by_period(%HistogramStatsRequest{} = histogram_stats_request, regions, skeleton) do
    region = if Enum.count(regions) == 1, do: regions |> List.first |> Map.get(:name), else: nil
    %{from_date: from_date, to_date: to_date, interval: interval} = histogram_stats_request
    date_params = %{"from" => from_date, "to" => to_date}
    msps =
      date_params
      |> msps_by_intervals_query(region, interval)
      |> Repo.all
    doctors =
      date_params
      |> doctors_by_intervals_query(region, interval)
      |> Repo.all
    total_declarations =
      date_params
      |> declarations_by_intervals_query(region, interval)
      |> Repo.all
    created_declarations =
      date_params
      |> declarations_by_intervals_query(region, interval, "active")
      |> Repo.all
    closed_declarations =
      date_params
      |> declarations_by_intervals_query(region, interval, "terminated")
      |> Repo.all

    skeleton
    |> add_to_histogram_skeleton(msps, ~w(period msps))
    |> add_to_histogram_skeleton(doctors, ~w(period doctors))
    |> add_to_histogram_skeleton(total_declarations, ~w(period declarations_total))
    |> add_to_histogram_skeleton(created_declarations, ~w(period declarations_created))
    |> add_to_histogram_skeleton(closed_declarations, ~w(period declarations_closed))
  end

  defp histogram_stats_by_date(%HistogramStatsRequest{} = histogram_stats_request, regions, skeleton) do
    region = if Enum.count(regions) == 1, do: regions |> List.first |> Map.get(:name), else: nil
    %{to_date: date, interval: interval} = histogram_stats_request
    date_params = %{"to" => date}
    msps =
      date_params
      |> msps_by_intervals_query(region, interval)
      |> Repo.all
    doctors =
      date_params
      |> doctors_by_intervals_query(region, interval)
      |> Repo.all
    total_declarations =
      date_params
      |> declarations_by_intervals_query(region, interval)
      |> Repo.all
    created_declarations =
      date_params
      |> declarations_by_intervals_query(region, interval, "active")
      |> Repo.all
    closed_declarations =
      date_params
      |> declarations_by_intervals_query(region, interval, "terminated")
      |> Repo.all

    skeleton
    |> add_to_histogram_skeleton(msps, ~w(total msps))
    |> add_to_histogram_skeleton(doctors, ~w(total doctors))
    |> add_to_histogram_skeleton(total_declarations, ~w(total declarations_total))
    |> add_to_histogram_skeleton(created_declarations, ~w(total declarations_created))
    |> add_to_histogram_skeleton(closed_declarations, ~w(total declarations_closed))
  end

  def histogram_stats_skeleton([intervals], histogram_stats_request) do
    histogram_stats_skeleton([intervals, intervals], histogram_stats_request)
  end
  def histogram_stats_skeleton(intervals, %HistogramStatsRequest{interval: interval, to_date: to_date}) do
    Enum.reduce(intervals, %{}, fn date, acc ->
      period_from = format_date(date)
      period_to =
        to_date
        |> min_date(get_interval_to_date(date, interval))
        |> format_date()
      value = %{
        "interval" => %{
          "from_date" => period_from,
          "to_date" => period_to
        },
        "period" => %{
          "msps" => 0,
          "doctors" => 0,
          "declarations_total" => 0,
          "declarations_created" => 0,
          "declarations_closed" => 0,
        },
        "total" => %{
          "msps" => 0,
          "doctors" => 0,
          "declarations_total" => 0,
          "declarations_created" => 0,
          "declarations_closed" => 0,
        }
      }
      Map.put(acc, format_date(date, interval), value)
    end)
  end

  defp add_to_histogram_skeleton(skeleton, values, keys) do
    Enum.reduce(values, skeleton, fn %{count: value, date: date}, acc ->
      date = if is_binary(date), do: date, else: date |> Timex.to_date() |> to_string()
      put_in(acc, [date | keys], value)
    end)
  end

  defp get_regions(nil), do: {:ok, Repo.all(Region)}
  defp get_regions(id) do
    case Repo.get(Region, id) do
      nil -> {:error, :not_found}
      region -> {:ok, [region]}
    end
  end

  defp declarations_by_period(from_date, to_date, status) do
    DeclarationStatusHistory
    |> interval_query(from_date, to_date)
    |> select([dsh], %{
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
    |> where([e], e.x == 1 and e.status == ^status)
    |> select([e], count(e.x))
    |> Repo.one!
  end

  defp msps_by_regions(date_params, region) do
    LegalEntity
    |> params_query(legal_entity_params())
    |> add_date_query(date_params)
    |> select([le], %{address: fragment("jsonb_array_elements(?)", le.addresses)})
    |> subquery()
    |> where([a], fragment("?->>'type' = 'REGISTRATION'", a.address))
    |> group_by([a], fragment("?->>'area'", a.address))
    |> add_area_query(region)
    |> select([a], %{region: fragment("?->>'area'", a.address), count: count(a.address)})
    |> Repo.all
  end

  defp doctors_by_regions(date_params, region) do
    Employee
    |> params_query(doctor_params())
    |> add_date_query(date_params)
    |> join(:left, [e], le in assoc(e, :legal_entity))
    |> select([e, le], %{address: fragment("jsonb_array_elements(?)", le.addresses)})
    |> subquery()
    |> where([a], fragment("?->>'type' = 'REGISTRATION'", a.address))
    |> group_by([a], fragment("?->>'area'", a.address))
    |> add_area_query(region)
    |> select([a], %{region: fragment("?->>'area'", a.address), count: count(a.address)})
    |> Repo.all
  end

  defp declarations_by_regions(date_params, region, status \\ nil) do
    Declaration
    |> add_date_query(date_params)
    |> join(:left, [d], dv in assoc(d, :division))
    |> select([d, dv], %{
      address: fragment("jsonb_array_elements(?)", dv.addresses),
      status: d.status
    })
    |> subquery()
    |> where([a], fragment("?->>'type' = 'REGISTRATION'", a.address))
    |> declaration_status_query(status)
    |> group_by([a], fragment("?->>'area'", a.address))
    |> add_area_query(region)
    |> select([a], %{region: fragment("?->>'area'", a.address), count: count(a.address)})
    |> Repo.all
  end

  defp declarations_by_regions_periods(date_params, region, status) do
    DeclarationStatusHistory
    |> add_date_query(date_params)
    |> join(:left, [dsh], d in assoc(dsh, :declaration))
    |> join(:left, [dsh, d], dv in assoc(d, :division))
    |> select([dsh, d, dv], %{
      address: fragment("jsonb_array_elements(?)", dv.addresses),
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
    |> declaration_status_query(status)
    |> group_by([a], fragment("?->>'area'", a.address))
    |> add_area_query(region)
    |> select([a], %{region: fragment("?->>'area'", a.address), count: count(a.address)})
    |> Repo.all
  end

  defp msps_by_intervals_query(date_params, region, "DAY") do
    # Example query:
    #
    # SELECT max(y.count), to_char(y.inserted_at, 'YYYY-MM') from (
    #   SELECT sum(x.count) OVER (ORDER BY x.inserted_at) as count, inserted_at FROM (
    #     SELECT
    #       jsonb_array_elements(addresses) AS address,
    #       count(id) AS count,
    #       inserted_at::date AS inserted_at
    #     FROM legal_entities
    #     WHERE
    #     (is_active = true) AND
    #     (inserted_at::date >= '2017-01-01') AND (inserted_at::date <= '2017-07-24')
    #     GROUP BY  inserted_at::date, jsonb_array_elements(addresses)
    #   ) AS x
    #   WHERE (x.address->>'type' = 'REGISTRATION') AND x.address->>'area' = '...'
    # GROUP BY x.inserted_at, x.count
    # ) as y
    # GROUP BY to_char(y.inserted_at, 'YYYY-MM');

    LegalEntity
    |> params_query(legal_entity_params())
    |> add_date_query(date_params)
    |> select([e], %{
      address: fragment("jsonb_array_elements(?)", e.addresses),
      count: count(e.id),
      inserted_at: fragment("?::date", e.inserted_at),
    })
    |> group_by([e], [
      fragment("?::date", e.inserted_at),
      fragment("jsonb_array_elements(?)", e.addresses)
    ])
    |> subquery()
    |> where([a], fragment("?->>'type' = 'REGISTRATION'", a.address))
    |> add_area_query(region)
    |> group_by([a], [a.inserted_at, a.count])
    |> select([a], %{
      count: fragment("sum(cast(? as int)) OVER (ORDER BY ?)", a.count, a.inserted_at),
      date: a.inserted_at,
    })
  end
  defp msps_by_intervals_query(date_params, region, "MONTH") do
    date_params
    |> msps_by_intervals_query(region, HistogramStatsRequest.interval(:day))
    |> subquery()
    |> histogram_month_query()
  end
  defp msps_by_intervals_query(date_params, region, "YEAR") do
    date_params
    |> msps_by_intervals_query(region, HistogramStatsRequest.interval(:day))
    |> subquery()
    |> histogram_year_query()
  end

  defp doctors_by_intervals_query(date_params, region, "DAY") do
    # Example query:
    #
    # SELECT max(y.count), to_char(y.inserted_at, 'YYYY-MM') from (
    #   SELECT sum(x.count) OVER (ORDER BY x.inserted_at) as count, inserted_at FROM (
    #     SELECT
    #       jsonb_array_elements(addresses) AS address,
    #       count(e.id) AS count,
    #       e.inserted_at::date AS inserted_at
    #     FROM employees e
    #     LEFT JOIN legal_entities le ON le.id = e.legal_entity_id
    #     WHERE
    #     (e.employee_type = 'DOCTOR') AND
    #     (e.inserted_at::date >= '2017-01-01') AND (e.inserted_at::date <= '2017-07-24')
    #     GROUP BY e.inserted_at::date, jsonb_array_elements(le.addresses)
    #   ) AS x
    #   WHERE (x.address->>'type' = 'REGISTRATION')
    # GROUP BY x.inserted_at, x.count
    # ) as y
    # GROUP BY to_char(y.inserted_at, 'YYYY-MM');

    Employee
    |> params_query(doctor_params())
    |> add_date_query(date_params)
    |> join(:left, [e], le in assoc(e, :legal_entity))
    |> select([e, le], %{
      address: fragment("jsonb_array_elements(?)", le.addresses),
      count: count(e.id),
      inserted_at: fragment("?::date", e.inserted_at),
    })
    |> group_by([e, le], [
      fragment("?::date", e.inserted_at),
      fragment("jsonb_array_elements(?)", le.addresses)
    ])
    |> subquery()
    |> where([a], fragment("?->>'type' = 'REGISTRATION'", a.address))
    |> add_area_query(region)
    |> group_by([a], [a.inserted_at, a.count])
    |> select([a], %{
      count: fragment("sum(cast(? as int)) OVER (ORDER BY ?)", a.count, a.inserted_at),
      date: a.inserted_at,
    })
  end
  defp doctors_by_intervals_query(date_params, region, "MONTH") do
    date_params
    |> doctors_by_intervals_query(region, HistogramStatsRequest.interval(:day))
    |> subquery()
    |> histogram_month_query()
  end
  defp doctors_by_intervals_query(date_params, region, "YEAR") do
    date_params
    |> doctors_by_intervals_query(region, HistogramStatsRequest.interval(:day))
    |> subquery()
    |> histogram_year_query()
  end

  defp declarations_by_intervals_query(date_params, region, "DAY") do
    # Example query:
    #
    # SELECT max(y.count), to_char(y.inserted_at, 'YYYY-MM') from (
    #   SELECT sum(x.count) OVER (ORDER BY x.inserted_at) as count, inserted_at FROM (
    #     SELECT
    #         jsonb_array_elements(dv.addresses) AS address,
    #         count(d.id) AS count,
    #         d.inserted_at::date AS inserted_at
    #     FROM declarations d
    #     LEFT JOIN divisions dv ON dv.id = d.division_id
    #     WHERE (d.inserted_at::date >= '2017-01-01') AND (d.inserted_at::date <= '2017-07-24')
    #     GROUP BY d.inserted_at::date, jsonb_array_elements(dv.addresses)
    #   ) AS x
    #   WHERE (x.address->>'type' = 'REGISTRATION')
    # GROUP BY x.inserted_at, x.count
    # ) as y
    # GROUP BY to_char(y.inserted_at, 'YYYY-MM');

    Declaration
    |> add_date_query(date_params)
    |> join(:left, [d], dv in assoc(d, :division))
    |> select([d, dv], %{
      address: fragment("jsonb_array_elements(?)", dv.addresses),
      count: count(d.id),
      inserted_at: fragment("?::date", d.inserted_at),
    })
    |> group_by([d, dv], [
      fragment("?::date", d.inserted_at),
      fragment("jsonb_array_elements(?)", dv.addresses)
    ])
    |> subquery()
    |> where([a], fragment("?->>'type' = 'REGISTRATION'", a.address))
    |> add_area_query(region)
    |> group_by([a], [a.inserted_at, a.count])
    |> select([a], %{
      count: fragment("sum(cast(? as int)) OVER (ORDER BY ?)", a.count, a.inserted_at),
      date: a.inserted_at,
    })
  end
  defp declarations_by_intervals_query(date_params, region, "MONTH") do
    date_params
    |> declarations_by_intervals_query(region, HistogramStatsRequest.interval(:day))
    |> subquery()
    |> histogram_month_query()
  end
  defp declarations_by_intervals_query(date_params, region, "YEAR") do
    date_params
    |> declarations_by_intervals_query(region, HistogramStatsRequest.interval(:day))
    |> subquery()
    |> histogram_year_query()
  end

  defp declarations_by_intervals_query(date_params, region, "DAY", status) do
    # Example query:
    #
    # SELECT max(y.count), to_char(y.inserted_at, 'YYYY-MM') FROM (
    #   SELECT sum(x.count) OVER (ORDER BY x.inserted_at) as count, inserted_at FROM (
    #     SELECT count(*), inserted_at from (
    #       SELECT
    #         jsonb_array_elements(dv.addresses) AS address,
    #         dsh.status,
    #         dsh.declaration_id,
    #         rank() OVER (PARTITION BY dsh.declaration_id ORDER BY dsh.inserted_at DESC) as x,
    #         dsh.inserted_at::date AS inserted_at
    #       FROM declarations_status_hstr dsh
    #       LEFT JOIN declarations d ON d.id = dsh.declaration_id
    #       LEFT JOIN divisions dv ON dv.id = d.division_id
    #     ) as a
    #     WHERE a.x = 1 AND a.status = 'active' AND a.address->>'area' = '...'
    #     GROUP BY a.inserted_at
    #   ) as x
    # ) as y
    # GROUP BY to_char(y.inserted_at, 'YYYY-MM');

    DeclarationStatusHistory
    |> add_date_query(date_params)
    |> join(:left, [dsh], d in assoc(dsh, :declaration))
    |> join(:left, [dsh, d], dv in assoc(d, :division))
    |> select([dsh, d, dv], %{
      address: fragment("jsonb_array_elements(?)", dv.addresses),
      status: dsh.status,
      declaration_id: dsh.declaration_id,
      x: fragment("""
      rank() OVER (
      PARTITION BY ?
      ORDER BY ? DESC
      )
      """, dsh.declaration_id, dsh.inserted_at),
      inserted_at: fragment("?::date", dsh.inserted_at)
    })
    |> subquery()
    |> where([a], a.x == 1)
    |> declaration_status_query(status)
    |> group_by([a], a.inserted_at)
    |> add_area_query(region)
    |> select([a], %{inserted_at: a.inserted_at, count: count(a.address)})
    |> subquery()
    |> select([a], %{
      date: a.inserted_at,
      count: fragment("sum(cast(? as int)) OVER (ORDER BY ?)", a.count, a.inserted_at)
    })
  end
  defp declarations_by_intervals_query(date_params, region, "MONTH", status) do
    date_params
    |> declarations_by_intervals_query(region, HistogramStatsRequest.interval(:day), status)
    |> subquery()
    |> histogram_month_query()
  end
  defp declarations_by_intervals_query(date_params, region, "YEAR", status) do
    date_params
    |> declarations_by_intervals_query(region, HistogramStatsRequest.interval(:day), status)
    |> subquery()
    |> histogram_year_query()
  end

  defp declaration_status_query(query, nil), do: query
  defp declaration_status_query(query, status), do: params_query(query, %{"status" => status})

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

  defp min_date(date1, date2) do
    case Timex.compare(date1, date2) do
      -1 -> date1
      _ -> date2
    end
  end

  defp format_date(date), do: format_date(date, HistogramStatsRequest.interval(:day))
  defp format_date(date, "DAY"), do: Timex.format!(date, "%F", :strftime)
  defp format_date(date, "MONTH"), do: Timex.format!(date, "%Y-%m", :strftime)
  defp format_date(date, "YEAR"), do: Timex.format!(date, "%Y", :strftime)

  defp histogram_month_query(query) do
    query
    |> select([a], %{count: max(a.count), date: fragment("to_char(?, 'YYYY-MM')", a.date)})
    |> group_by([a], fragment("to_char(?, 'YYYY-MM')", a.date))
  end

  defp histogram_year_query(query) do
    query
    |> select([a], %{count: max(a.count), date: fragment("to_char(?, 'YYYY')", a.date)})
    |> group_by([a], fragment("to_char(?, 'YYYY')", a.date))
  end
end
