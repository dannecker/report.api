defmodule Report.Replica.Replicas do
  @moduledoc """
  Context module for working with Replica Schemas
  """
  import Ecto.Query
  alias Report.Replica.Declaration
  alias Report.Repo

  def list_declarations do
    declaration_query()
    |> preload_declaration_assoc()
    |> Repo.all
  end

  def stream_declarations_beetween(_from, _to) do
    declaration_query()
    |> preload_declaration_assoc()
    |> Repo.stream(timeout: 30_000)
  end

  def get_oldest_declaration_date do
    declaration_query()
    |> select([:inserted_at])
    |> last
    |> Repo.one
    |> get_inserted_at
  end
  defp get_inserted_at(nil), do: DateTime.utc_now()
  defp get_inserted_at(declaration) when is_map(declaration), do: Map.get(declaration, :inserted_at)

  defp declaration_query do
    from(d in Declaration,
         where: d.status == "active",
         where: d.is_active,
         order_by: [desc: :inserted_at])
  end

  defp preload_declaration_assoc(query) do
    query
    |> join(:left, [declaration], person in assoc(declaration, :person))
    |> join(:left, [declaration], legal_entity in assoc(declaration, :legal_entity))
    |> join(:left, [declaration], division in assoc(declaration, :division))
    |> preload([declaration, person, legal_entity, division],
               [person: person, legal_entity: legal_entity, division: division])
  end

  def params_query(query, params) when is_map(params) do
    params =
      params
      |> Enum.map(fn
        ({key, value}) when is_bitstring(key) -> {String.to_atom(key), value}
        ({key, value}) when is_atom(key) -> {key, value}
      end)
      |> Enum.filter(fn {k, v} -> !is_nil(v) end)
    where(query, ^params)
  end

  def interval_query(query, from, to) do
    query
    |> gte_date_query(from)
    |> lte_date_query(to)
  end

  def gte_date_query(query, date) do
    where(query, [e], fragment("?::date >= ?", e.inserted_at, ^date))
  end

  def lte_date_query(query, date) do
    where(query, [e], fragment("?::date <= ?", e.inserted_at, ^date))
  end

  def lt_date_query(query, date) do
    where(query, [e], fragment("?::date < ?", e.inserted_at, ^date))
  end

  def count_query(query, field_name \\ :id) do
    query
    |> select([e], count(field(e, ^field_name)))
    |> Repo.one!
  end

  def ilike_query(query, _, nil), do: query
  def ilike_query(query, field_name, value) do
    where(query, [e], ilike(field(e, ^field_name), ^"%#{value}%"))
  end

  def add_date_query(query, %{"from" => from, "to" => to}), do: interval_query(query, from, to)
  def add_date_query(query, %{"to" => to}), do: lte_date_query(query, to)

  def add_area_query(query, nil), do: query
  def add_area_query(query, region) do
    where(query, [a], fragment("?->>'area'", a.address) == ^region)
  end
end
