defmodule Report.Reporter do
  @moduledoc false
  alias Report.Replica.Replicas
  alias Report.Billings
  alias Report.Repo
  alias Report.MediaStorage
  alias Report.ReportLog
  alias Report.ReportLogs

  def capitation(order \\ :sync) do
    generate_billing(order)
    generate_csv()
    file = File.read!("/tmp/capitation.csv")
    {:ok, public_url} = MediaStorage.store_signed_content(file, :capitation_report_bucket,
                                                           to_string(Timex.to_unix(Timex.now)),
                                                           [{"Content-Type", "application/json"}])
    {:ok, log} = ReportLogs.save_capitation_csv_url(%ReportLog{}, %{public_url: public_url})
    log
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

  def generate_csv do
    headers = ["edrpou", "name", "mountain_group", "0-5", "6-17", "18-39", "40-64", ">65"]
    file = File.stream!("/tmp/capitation.csv", [:write, :utf8])
    Billings.get_billing_for_capitation
    |> Stream.chunk_by(&(&1[:edrpou]))
    |> Stream.map(&calcualte_total(&1, length(&1)))
    |> Stream.flat_map(fn x -> x end)
    |> CSV.encode(headers: headers)
    |> Stream.into(file)
    |> Stream.run
  end

  defp calcualte_total(billings, 2) do
    b_one = Enum.at(billings, 0)
    b_two = Enum.at(billings, 1)
    total_billing = [
      edrpou: b_one[:edrpou],
      name: b_one[:name],
      mountain_group: "MSP Total",
      "0-5": b_one[:"0-5"] + b_two[:"0-5"],
      "6-17": b_one[:"6-17"] + b_two[:"6-17"],
      "18-39": b_one[:"18-39"] + b_two[:"18-39"],
      "40-64": b_one[:"40-64"] + b_two[:"40-64"],
      ">65": b_one[:">65"] + b_two[:">65"]
    ]
    [list_to_map_strings(b_one)] ++ [list_to_map_strings(b_two)] ++ [list_to_map_strings(total_billing)]
  end

  defp calcualte_total(billings, 1) do
    billings = List.flatten(billings)
    temp_billing = [
      edrpou: billings[:edrpou],
      name: billings[:name],
      mountain_group: !billings[:mountain_group],
      "0-5": 0,
      "6-17": 0,
      "18-39": 0,
      "40-64": 0,
      ">65": 0,
    ]
    total_billing = [
      edrpou: billings[:edrpou],
      name: billings[:name],
      mountain_group: "MSP Total",
      "0-5": billings[:"0-5"],
      "6-17": billings[:"6-17"],
      "18-39": billings[:"18-39"],
      "40-64": billings[:"40-64"],
      ">65": billings[:">65"]
    ]
    [list_to_map_strings(temp_billing)] ++ [list_to_map_strings(billings)] ++ [list_to_map_strings(total_billing)]
  end

  defp list_to_map_strings(list) do
    list
    |> Enum.map(fn {k, v} -> {to_string(k), to_string_names(v)} end)
    |> Enum.into(%{})
  end

  defp to_string_names(value) when is_boolean(value)  do
    bools = [true: "MSP Mountain", false: "MSP Regular"]
    bools[value]
  end
  defp to_string_names(value), do: to_string(value)

  defp declaration_each(items, :sync) do
    Stream.each(items, fn(item) -> Billings.create_billing(item) end)
  end
  defp declaration_each(items, :async) do
    Task.async_stream(items, Billings, :create_billing, [], [])
  end
end
