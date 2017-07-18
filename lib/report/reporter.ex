defmodule Report.Reporter do
  @moduledoc false
  alias Report.Replica.Replicas
  alias Report.Billings
  alias Report.Repo

  def capitation(order \\ :sync) do
    generate_billing(order)
  end

  def generate_billing(order \\ :sync) do
    last_billing_datetime = Timex.to_datetime(Billings.get_last_billing_date())
    to_date =  Timex.to_datetime(Timex.shift(Timex.today(), hours: 24))
    Repo.transaction(fn ->
      last_billing_datetime
      |> Replicas.stream_declarations_beetween(to_date)
      |> declaration_each(order)
      |> Stream.run
    end)
  end

  defp declaration_each(items, :sync) do
    Stream.each(items, fn(item) -> Billings.create_billing(item) end)
  end
  defp declaration_each(items, :async) do
    Task.async_stream(items, Billings, :create_billing, [], [])
  end
end
