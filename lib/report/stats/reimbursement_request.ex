defmodule Report.Stats.ReimbursementRequest do
  @moduledoc false

  use Ecto.Schema

  @primary_key false

  schema "reimbursement_request" do
    embeds_one :period, Report.Stats.ReimbursementRequest.EmbeddedData
  end
end

defmodule Report.Stats.ReimbursementRequest.EmbeddedData do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    embeds_one :request, Report.Stats.ReimbursementRequest.Period
    embeds_one :dispense, Report.Stats.ReimbursementRequest.Period
  end

  def changeset(entity, params \\ %{}) do
    entity
    |> change(params)
    |> cast_embed(:request)
    |> cast_embed(:dispense)
  end
end

defmodule Report.Stats.ReimbursementRequest.Period do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :from, :date
    field :to, :date
  end

  def changeset(model, params \\ %{}) do
    cast(model, params, ~w(from to)a)
  end
end
