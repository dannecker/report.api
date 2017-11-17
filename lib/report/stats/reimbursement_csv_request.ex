defmodule Report.Stats.ReimbursementCSVRequest do
  @moduledoc false

  use Ecto.Schema

  @primary_key false

  schema "reimbursement_csv_request" do
    field :date_from_dispense, :date
    field :date_to_dispense, :date
  end
end
