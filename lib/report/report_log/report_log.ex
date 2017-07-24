defmodule Report.ReportLog do
  @moduledoc """
    Ecto Schema for Billing table
  """
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "report_logs" do
    field :type, :string
    field :public_url, :string
    timestamps(type: :utc_datetime, updated_at: false)
  end
end
