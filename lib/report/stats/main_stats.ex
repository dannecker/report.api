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

  import Ecto.Changeset
  import Ecto.Query
  import Report.Replica.Replicas

  @fields_main_stats ~w(from_date to_date)a
  @fields_required_main_stats ~w(from_date to_date)a

  @fields_regions_stats ~w(from_date to_date region_id)a
  @fields_required_regions_stats ~w(from_date to_date)a

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
    created_declarations = declarations_by_regions_periods(from_date, to_date, region, "active")
    closed_declarations = declarations_by_regions_periods(from_date, to_date, region, "terminated")

    skeleton
    |> add_to_skeleton(msps, ~w(period msps))
    |> add_to_skeleton(doctors, ~w(period doctors))
    |> add_to_skeleton(total_declarations, ~w(period declarations_total))
    |> add_to_skeleton(created_declarations, ~w(period declarations_created))
    |> add_to_skeleton(closed_declarations, ~w(period declarations_closed))
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
    |> add_to_skeleton(msps, ~w(total msps))
    |> add_to_skeleton(doctors, ~w(total doctors))
    |> add_to_skeleton(total_declarations, ~w(total declarations_total))
    |> add_to_skeleton(created_declarations, ~w(total declarations_created))
    |> add_to_skeleton(closed_declarations, ~w(total declarations_closed))
  end

  defp add_to_skeleton(skeleton, values, keys) do
    Enum.reduce(values, skeleton, fn %{count: value, region: name}, acc ->
      put_in(acc, [name | keys], value)
    end)
  end

  defp get_regions(nil), do: {:ok, Repo.all(Region)}
  defp get_regions(id) do
    case Repo.get(Region, id) do
      nil -> {:error, {:conflict, "Invalid region id"}}
      region -> {:ok, [region]}
    end
  end

  defp main_stats_changeset(%MainStatsRequest{} = main_stats_request, params) do
    main_stats_request
    |> cast(params, @fields_main_stats)
    |> validate_required(@fields_required_main_stats)
    |> validate_period()
  end

  defp regions_stats_changeset(%RegionsStatsRequest{} = regions_stats_request, params) do
    regions_stats_request
    |> cast(params, @fields_regions_stats)
    |> validate_required(@fields_required_regions_stats)
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
    |> add_declaration_status_query(status)
    |> group_by([a], fragment("?->>'area'", a.address))
    |> add_area_query(region)
    |> select([a], %{region: fragment("?->>'area'", a.address), count: count(a.address)})
    |> Repo.all
  end

  defp declarations_by_regions_periods(from_date, to_date, region, status) do
    DeclarationStatusHistory
    |> interval_query(from_date, to_date)
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
    |> add_declaration_status_query(status)
    |> group_by([a], fragment("?->>'area'", a.address))
    |> add_area_query(region)
    |> select([a], %{region: fragment("?->>'area'", a.address), count: count(a.address)})
    |> Repo.all
  end

  defp add_declaration_status_query(query, nil), do: query
  defp add_declaration_status_query(query, status), do: params_query(query, %{"status" => status})

  defp doctor_params do
    %{"employee_type" => "DOCTOR", "status" => "APPROVED", "is_active" => true}
  end

  defp legal_entity_params, do: %{"is_active" => true}
end
