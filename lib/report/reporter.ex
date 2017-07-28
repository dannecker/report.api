defmodule Report.Reporter do
  @moduledoc false
  alias Report.Replica.Replicas
  alias Report.Billings
  alias Report.Repo
  alias Report.MediaStorage
  alias Report.ReportLog
  alias Report.ReportLogs
  alias Report.BillingProducer

  def capitation do
    order = Confex.get(:report_api, :async_billing)
    generate_billing(order)
    generate_csv()
    file = File.read!("/tmp/capitation.csv")
    {:ok, public_url} =
      MediaStorage.store_signed_content(file, :capitation_report_bucket,
        to_string(Timex.to_unix(Timex.now)), [{"Content-Type", "application/json"}])
    {:ok, log} = ReportLogs.save_capitation_csv_url(%ReportLog{}, %{public_url: public_url})
    log
  end

  def generate_billing(async \\ false) do
    last_billing_datetime = Timex.to_datetime(Billings.get_last_billing_date())
    to_date =  Timex.to_datetime(Timex.shift(Timex.today(), hours: 24))
    Repo.transaction(fn ->
      last_billing_datetime
      |> Replicas.stream_declarations_beetween(to_date)
      |> Stream.each(fn billing -> Billings.create_billing(billing) end)
      |> Stream.run
    end, timeout: 120_000)
  end

  def generate_csv do
    file = File.stream!("/tmp/capitation.csv", [:write, :utf8])
    Repo.transaction(fn ->
      Billings.get_billing_for_capitation
      |> Stream.chunk_by(fn x -> Enum.at(x, 0) end)
      |> Stream.map(&calcualte_total(&1, length(&1)))
      |> Stream.flat_map(fn x -> x end)
      |> CSV.encode()
      |> Stream.into(file)
      |> Stream.run
    end, timeout: 120_000)
  end

  defp calcualte_total(billings, 2) do
    b_one = Enum.at(billings, 0)
    b_two = Enum.at(billings, 1)
    [edrpou1, name1, _, age1_1, age2_1, age3_1, age4_1, age5_1] = b_one
    [_, _, _, age1_2, age2_2, age3_2, age4_2, age5_2]           = b_two
    total_billing = [
      edrpou1, name1, "MSP Total", age1_1 + age1_2, age2_1 + age2_2, age3_1 + age3_2, age4_1 + age4_2, age5_1 + age5_2
    ]
    list = [list_to_map_strings(b_one)] ++ [list_to_map_strings(b_two)] ++ [list_to_map_strings(total_billing)]
    sort_by_mountain_group(list)
  end

  defp calcualte_total(billings, 1) do
    billings = List.flatten(billings)
    [edrpou, name, mountain_group, age1, age2, age3, age4, age5] = billings
    mountain_group = present?(mountain_group)
    temp_billing = [edrpou, name, !mountain_group, 0, 0, 0, 0, 0]
    total_billing = [edrpou, name, "MSP Total", age1, age2, age3, age4, age5]
    list = [list_to_map_strings(temp_billing)] ++
           [list_to_map_strings(billings)] ++
           [list_to_map_strings(total_billing)]
    sort_by_mountain_group(list)
  end

  defp list_to_map_strings(list) do
    Enum.map(list, fn v -> to_string_names(v) end)
  end

  defp to_string_names(value) when is_boolean(value) or is_nil(value)  do
    bools = [true: "MSP Mountain", false: "MSP Regular", nil: "MSP Regular"]
    bools[value]
  end
  defp to_string_names(value), do: to_string(value)

  defp sort_by_mountain_group(list) do
    mapper =
      fn([_, _, group, _, _, _, _, _]) ->
        case group do
          "MSP Mountain" -> 1
          "MSP Regular"  -> 2
          "MSP Total"    -> 3
        end
      end
    Enum.sort_by(list, &(mapper.(&1)), &<=/2)
  end

  defp present?(nil), do: false
  defp present?(false), do: false
  defp present?(_), do: true
end
