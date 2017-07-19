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

  def stream_declarations_beetween(from, to) do
    declaration_query()
    # |> where_beetween(from, to)
    |> preload_declaration_assoc()
    |> Repo.stream(timeout: 120_000_000)
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

  defp where_beetween(query, from, to) do
    query
    |> where([d], d.inserted_at >= ^from)
    |> where([d], d.inserted_at <= ^to)
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
    params = Enum.map(params, fn
      ({key, value}) when is_bitstring(key) -> {String.to_atom(key), value}
      ({key, value}) when is_atom(key) -> {key, value}
    end)
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

  def count_query(query, field_name \\ :id) do
    query
    |> select([e], count(field(e, ^field_name)))
    |> Repo.one!
  end
end
