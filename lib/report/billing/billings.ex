defmodule Report.Billings do
  @moduledoc false
  require Logger
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

  def create_billing(%Declaration{person: person, division: division} = declaration) do
    with billing_chset <- billing_changeset(%Billing{}, declaration, person, division),
         {:ok, billing} <- Repo.insert(billing_chset)
    do
      Logger.info fn -> "Billing was created for #{billing.declaration.id}" end
      billing
    else
      {:error, error_chset} ->
        Logger.error fn -> """
          #{error_chset.errors} for
          declaration_id=#error_chsetchanges.declaration.data.id}
          legal_entity_id=#error_chsetchanges.legal_entity.data.id}
          """
        end
    end
  end

  def billing_changeset(billing, declaration, person, division) do
    billing
    |> cast(%{}, [])
    |> put_assoc(:legal_entity, declaration.legal_entity)
    |> put_assoc(:declaration, declaration)
    |> put_assoc(:division, division)
    |> put_mountain_group(division)
    |> put_person_age(person)
  end

  defp put_mountain_group(billing_chset, division) do
    put_change(billing_chset, :mountain_group, division.mountain_group)
  end

  defp put_person_age(billing_chset, person) do
    person_age = Timex.diff(Timex.today, person.birth_date, :years)
    put_change(billing_chset, :person_age, person_age)
  end
end
