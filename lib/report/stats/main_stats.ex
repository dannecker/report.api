defmodule Report.Stats.MainStats do
  @moduledoc false

  alias Report.Repo
  alias Report.Replica.Declaration
  alias Report.Replica.Employee
  alias Report.Replica.LegalEntity
  alias Report.Stats.MainStatsRequest

  import Ecto.Changeset
  import Ecto.Query
  import Ecto.Adapters.SQL
  import Report.Replica.Replicas

  @fields_main_stats ~w(from_date to_date)a
  @fields_required_main_stats ~w(from_date to_date)a

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

  def main_stats_by_period(%MainStatsRequest{from_date: from_date, to_date: to_date}) do
    msps =
      LegalEntity
      |> interval_query(from_date, to_date)
      |> count_query()

    doctors =
      Employee
      |> params_query(%{"employee_type" => "DOCTOR"})
      |> interval_query(from_date, to_date)
      |> count_query()

    # select count(*) from declarations where inserted_at <= to_date
    total_declarations =
      Declaration
      |> lte_date_query(to_date)
      |> count_query()

    %{rows: [[created_declarations]]} = created_declarations_by_period(from_date, to_date)
    %{rows: [[closed_declarations]]} = closed_declarations_by_period(from_date, to_date)

    %{
      "declarations_total" => total_declarations,
      "declarations_created" => created_declarations,
      "declarations_closed" => closed_declarations,
      "msps" => msps,
      "doctors" => doctors,
    }
  end

  def main_stats_by_date(date) do
    msps = LegalEntity
    |> where([le], fragment("?::date >= ?", le.inserted_at, ^date))
    |> select([le], count(le.id))
    |> Repo.one!

    doctors = Employee
    |> where([e], fragment("?::date >= ?", e.inserted_at, ^date))
    |> where([e], e.employee_type == "DOCTOR")
    |> select([e], count(e.id))
    |> Repo.one!

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

  defp main_stats_changeset(%MainStatsRequest{} = main_stats_request, params) do
    main_stats_request
    |> cast(params, @fields_main_stats)
    |> validate_required(@fields_required_main_stats)
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

  defp created_declarations_by_period(from_date, to_date) do
    sql = """
      SELECT count(*) FROM
      (
        SELECT status, declaration_id, rank() OVER (
        PARTITION BY declaration_id
        ORDER BY inserted_at DESC
        ) AS x
        FROM declarations_status_hstr
        WHERE inserted_at::date BETWEEN $1::date AND $2::date
      ) AS y
      WHERE y.x = 1 AND status = 'active';
    """
    query!(Repo, sql, [from_date, to_date])
  end

  defp closed_declarations_by_period(from_date, to_date) do
    sql = """
      SELECT count(*) FROM
      (
        SELECT status, declaration_id, rank() OVER (
        PARTITION BY declaration_id
        ORDER BY inserted_at DESC
        ) AS x
        FROM declarations_status_hstr
        WHERE inserted_at::date BETWEEN $1::date AND $2::date
      ) AS y
      WHERE y.x = 1 AND status = 'terminated';
    """
    query!(Repo, sql, [from_date, to_date])
  end
end
