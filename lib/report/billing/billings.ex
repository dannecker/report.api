defmodule Report.Billings do
  @moduledoc false
  import Ecto.Query
  import Ecto.Changeset
  alias Report.Billing
  alias Report.Repo
  alias Report.Replica.Replicas
  alias Report.Replica.Declaration

  def get_last_billing_date do
    Billing
    |> select([:billing_date])
    |> order_by([desc: :billing_date])
    |> first
    |> Repo.one
    |> get_billing_date
  end
  defp get_billing_date(nil), do: Replicas.get_oldest_declaration_date()
  defp get_billing_date(billing) when is_map(billing), do: Map.get(billing, :billing_date)

  def create_billing(%Declaration{person: person, legal_entity: legal_entity} = declaration) do
    # require IEx; IEx.pry
    # TODO: ask about age_group params and mountain_group
  end

  def billing_changeset(billing, attrs \\ %{}) do
    billing
    |> cast(attrs, [:declaration_id, :legal_entity, :mountain_group, :age_group])
  end
end
