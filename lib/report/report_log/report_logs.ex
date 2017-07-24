defmodule Report.ReportLogs do
  @moduledoc false
  alias Report.ReportLog
  alias Report.Repo
  import Ecto.Changeset

  def list_report_logs do
    Repo.all(ReportLog)
  end

  def save_capitation_csv_url(schema, attrs \\ %{}) do
    schema
    |> cast(attrs, [:public_url])
    |> put_change(:type, "capitation")
    |> Repo.insert
  end
end
