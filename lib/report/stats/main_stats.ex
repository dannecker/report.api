defmodule Report.Stats.MainStats do
  @moduledoc false

  alias Report.Repo
  alias Report.Replica.Declaration
  alias Report.Replica.DeclarationStatusHistory
  alias Report.Replica.Division
  alias Report.Replica.Employee
  alias Report.Replica.LegalEntity
  alias Report.Replica.Region
  alias Report.Replica.MedicationRequest
  alias Report.Replica.MedicationRequestStatusHistory
  alias Report.Stats.HistogramStatsRequest

  import Ecto.Changeset, only: [apply_changes: 1]
  import Ecto.Query
  import Report.Replica.Replicas
  import Report.Stats.MainStatsValidator

  use Timex

  def get_main_stats do
    msps =
      LegalEntity
      |> params_query(msp_params())
      |> count_query()

    pharmacies =
      LegalEntity
      |> params_query(pharmacy_params())
      |> count_query()

    doctors =
      Employee
      |> params_query(doctor_params())
      |> count_query()

    pharmacists =
      Employee
      |> params_query(pharmacist_params())
      |> count_query()

    declarations =
      Declaration
      |> declaration_query()
      |> count_query()

    {:ok, %{
      "declarations" => declarations,
      "doctors" => doctors,
      "pharmacists" => pharmacists,
      "msps" => msps,
      "pharmacies" => pharmacies,
    }}
  end

  def get_division_stats(id) do
    division = Repo.get!(Division, id)

    msps =
      LegalEntity
      |> params_query(msp_params())
      |> join(:left, [le], d in Division, d.legal_entity_id == le.id)
      |> where([le, d], d.id == ^id)
      |> count_query()

    doctors =
      Employee
      |> params_query(Map.merge(doctor_params(), %{"division_id" => id}))
      |> count_query()

    declarations =
      Declaration
      |> params_query(%{"division_id" => id})
      |> declaration_query()
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

  def get_regions_stats do
    with skeleton <- regions_stats_skeleton(Repo.all(Region)),
         skeleton <- add_to_regions_skeleton(msps_by_regions(), ["stats", "msps"], skeleton),
         skeleton <- add_to_regions_skeleton(pharmacies_by_regions(), ["stats", "pharmacies"], skeleton),
         skeleton <- add_to_regions_skeleton(doctors_by_regions(), ["stats", "doctors"], skeleton),
         skeleton <- add_to_regions_skeleton(pharmacists_by_regions(), ["stats", "pharmacists"], skeleton),
         skeleton <- add_to_regions_skeleton(declarations_by_regions(), ["stats", "declarations"], skeleton),
         skeleton <- add_to_regions_skeleton(medication_requests_by_regions(), ~w(stats medication_requests), skeleton)
    do
      {:ok, Map.values(skeleton)}
    end
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

    active_medication_requests = active_medication_requests_by_date(from_date)
    created_medication_requests =
      MedicationRequest
      |> interval_query(from_date, to_date)
      |> medication_requests_by_intervals(interval)
      |> Repo.all
      |> Enum.into(%{}, fn %{count: count, date: date} ->
        {date, count}
      end)
    closed_medication_requests =
      MedicationRequestStatusHistory
      |> interval_query(from_date, to_date)
      |> where([mrsh], mrsh.status in ~w(COMPLETED))
      |> medication_requests_by_intervals(interval)
      |> Repo.all
      |> Enum.into(%{}, fn %{count: count, date: date} ->
        {date, count}
      end)

      head =
        skeleton
        |> hd()
        |> Map.put("declarations_active_start", active_declarations)
        |> Map.put("medication_requests_active_start", active_medication_requests)
    skeleton = [head | List.delete_at(skeleton, 0)]

    {skeleton, _} =
      skeleton
      |> Enum.with_index
      |> Enum.reduce({skeleton, nil}, fn {%{"period_name" => date} = value, i}, {acc, previous} ->
        declarations_active_start = if is_nil(previous),
          do: Map.get(value, "declarations_active_start"),
          else: Map.get(previous, "declarations_active_end")

        medication_requests_active_start = if is_nil(previous),
          do: Map.get(value, "medication_requests_active_start"),
          else: Map.get(previous, "medication_requests_active_end")

        created_declarations = Map.get(created_declarations, date, 0)
        closed_declarations = Map.get(closed_declarations, date, 0)
        declarations_active_end = declarations_active_start +
          created_declarations - closed_declarations

        created_medication_requests = Map.get(created_medication_requests, date, 0)
        closed_medication_requests = Map.get(closed_medication_requests, date, 0)
        medication_requests_active_end = medication_requests_active_start +
          created_medication_requests - closed_medication_requests
        new_value = %{value |
          "declarations_created" => created_declarations,
          "declarations_closed" => closed_declarations,
          "declarations_active_start" => declarations_active_start,
          "declarations_active_end" => declarations_active_end,
          "medication_requests_created" => created_medication_requests,
          "medication_requests_closed" => closed_medication_requests,
          "medication_requests_active_start" => medication_requests_active_start,
          "medication_requests_active_end" => medication_requests_active_end
        }
        {List.replace_at(acc, i, new_value), new_value}
      end)
    skeleton
  end

  defp declarations_by_intervals(query, "DAY"), do: histogram_day_query(query)
  defp declarations_by_intervals(query, "MONTH"), do: histogram_month_query(query)
  defp declarations_by_intervals(query, "YEAR"), do: histogram_year_query(query)

  defp medication_requests_by_intervals(query, "DAY"), do: histogram_day_query(query)
  defp medication_requests_by_intervals(query, "MONTH"), do: histogram_month_query(query)
  defp medication_requests_by_intervals(query, "YEAR"), do: histogram_year_query(query)

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
        "medication_requests_created" => 0,
        "medication_requests_closed" => 0,
        "medication_requests_active_start" => 0,
        "medication_requests_active_end" => 0,
      }
    end)
  end

  defp regions_stats_skeleton(regions) do
    Enum.into(regions, %{}, fn region ->
      {region.name, %{
        "region" => region,
        "stats" => %{
          "declarations" => 0,
          "doctors" => 0,
          "msps" => 0,
          "pharmacies" => 0,
          "pharmacists" => 0,
          "medication_requests" => 0,
        }
      }}
    end)
  end

  defp msps_by_regions do
    LegalEntity
    |> params_query(msp_params())
    |> legal_entities_by_regions()
  end

  defp pharmacies_by_regions do
    LegalEntity
    |> params_query(pharmacy_params())
    |> legal_entities_by_regions()
  end

  defp legal_entities_by_regions(query) do
    query
    |> where([le], fragment("? @> ?", le.addresses, ^[%{"type" => "REGISTRATION"}]))
    |> select([le], %{address: fragment("jsonb_array_elements(?)", le.addresses)})
    |> subquery()
    |> group_by([a], fragment("?->>'area'", a.address))
    |> where([a], fragment("?->>'type' = 'REGISTRATION'", a.address))
    |> select([a], %{region: fragment("?->>'area'", a.address), count: count(a.address)})
    |> Repo.all
  end

  defp doctors_by_regions do
    Employee
    |> params_query(%{"employee_type" => "DOCTOR"})
    |> employees_by_regions()
  end

  defp pharmacists_by_regions do
    Employee
    |> params_query(%{"employee_type" => "PHARMACIST"})
    |> employees_by_regions()
  end

  defp employees_by_regions(query) do
    query
    |> params_query(%{"status" => "APPROVED"})
    |> params_query(%{"is_active" => true})
    |> join(:left, [e], dv in assoc(e, :division))
    |> where([e, dv], fragment("? @> ?", dv.addresses, ^[%{"type" => "REGISTRATION"}]))
    |> select([e, dv], %{address: fragment("jsonb_array_elements(?)", dv.addresses)})
    |> subquery()
    |> group_by([a], fragment("?->>'area'", a.address))
    |> where([a], fragment("?->>'type' = 'REGISTRATION'", a.address))
    |> select([a], %{region: fragment("?->>'area'", a.address), count: count(a.address)})
    |> Repo.all
  end

  defp medication_requests_by_regions do
    MedicationRequest
    |> join(:left, [mr], e in assoc(mr, :employee))
    |> join(:left, [mr, e], d in assoc(e, :division))
    |> where([mr, e, d], fragment("? @> ?", d.addresses, ^[%{"type" => "REGISTRATION"}]))
    |> select([mr, e, d], %{address: fragment("jsonb_array_elements(?)", d.addresses)})
    |> subquery()
    |> group_by([a], fragment("?->>'area'", a.address))
    |> where([a], fragment("?->>'type' = 'REGISTRATION'", a.address))
    |> select([a], %{region: fragment("?->>'area'", a.address), count: count(a.address)})
    |> Repo.all
  end

  defp declarations_by_regions do
    Declaration
    |> declaration_query()
    |> join(:left, [d], dv in assoc(d, :division))
    |> where([d, dv], fragment("? @> ?", dv.addresses, ^[%{"type" => "REGISTRATION"}]))
    |> select([d, dv], %{address: fragment("jsonb_array_elements(?)", dv.addresses)})
    |> subquery()
    |> group_by([a], fragment("?->>'area'", a.address))
    |> where([a], fragment("?->>'type' = 'REGISTRATION'", a.address))
    |> select([a], %{region: fragment("?->>'area'", a.address), count: count(a.address)})
    |> Repo.all
  end

  defp add_to_regions_skeleton(data, keys, skeleton) do
    Enum.reduce(data, skeleton, fn %{count: count, region: region_name}, acc ->
      if Map.has_key?(acc, region_name),
        do: put_in(acc, [region_name | keys], count),
        else: acc
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
    |> declaration_query()
    |> select([a], count(a.declaration_id))
    |> Repo.one!
  end

  defp active_medication_requests_by_date(date) do
    MedicationRequestStatusHistory
    |> lt_date_query(date)
    |> join(:left, [mrsh], d in assoc(mrsh, :medication_request))
    |> select([mrsh, mr], %{
      status: mrsh.status,
      medication_request_id: mrsh.medication_request_id,
      x: fragment("""
      rank() OVER (
        PARTITION BY ?
        ORDER BY ? DESC
      )
      """, mrsh.medication_request_id, mrsh.inserted_at)
    })
    |> subquery()
    |> where([a], a.x == 1)
    |> medication_request_query()
    |> select([a], count(a.medication_request_id))
    |> Repo.one!
  end

  defp doctor_params do
    %{"employee_type" => "DOCTOR", "status" => "APPROVED", "is_active" => true}
  end

  defp pharmacist_params do
    %{"employee_type" => "PHARMACIST", "status" => "APPROVED", "is_active" => true}
  end

  defp declaration_query(query) do
    where(query, [d], d.status in ~w(active pending_verification))
  end

  defp medication_request_query(query) do
    where(query, [mr], mr.status in ~w(ACTIVE COMPLETED))
  end

  defp msp_params, do: %{"type" => "MSP", "is_active" => true}

  defp pharmacy_params, do: %{"type" => "PHARMACY", "is_active" => true}

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
