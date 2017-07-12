defmodule Report.Replica.Replicas do
  @moduledoc """
  Context module for working with Replica Schemas
  """
  import Ecto.Query
  alias Report.Replica.Declaration
  alias Report.Repo

  def list_declarations do
    Repo.all(declaration_query)
  end

  def stream_declrations_beetween(from, to) do
    declaration_query()
    |> where_beetween(from, to)
    |> Repo.stream(timeout: :infinity)
  end

  def declaration_query do
    from(d in Declaration)
  end

  def where_beetween(query, from, to) do
    query
    |> where([d], d.created_at >= ^from)
    |> where([d], d.created_at <= ^to)
  end
end
