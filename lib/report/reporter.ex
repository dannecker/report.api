defmodule Report.Reporter do
  @moduledoc false
  alias Report.Replica.Replicas
  alias Report.Billings
  alias Report.Repo

  def capitation do
    last_billing_datetime = Timex.to_datetime(Billings.get_last_billing_date())
    to_date =  Timex.to_datetime(Timex.shift(Timex.today(), hours: 24))
    new_declarations_stream = Replicas.stream_declarations_beetween(
      last_billing_datetime,
      to_date)
    Repo.transaction(fn ->
      new_declarations_stream
      |> Task.async_stream(Billings, :create_billing, [], [])
      # Enum.each(new_declarations_stream, fn(dec) -> Billings.create_billing(dec) end)
      |> Stream.run
    end)
  end
end
