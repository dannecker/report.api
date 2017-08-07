defmodule Report.Reporter do
  @moduledoc false
  alias Report.Replica.Replicas
  alias Report.Billings
  alias Report.Repo
  alias Report.MediaStorage
  alias Report.ReportLog
  alias Report.ReportLogs
  alias Report.RedLists

  @async_billing Confex.get_env(:report_api, :async_billing)

  def capitation do
    generate_billing()
    generate_csv()
    file = File.read!("/tmp/capitation.csv")
    {:ok, public_url} =
      MediaStorage.store_signed_content(file, :capitation_report_bucket,
        to_string(Timex.to_unix(Timex.now)), [{"Content-Type", "application/json"}])
    {:ok, log} = ReportLogs.save_capitation_csv_url(%ReportLog{}, %{public_url: public_url})
    log
  end

  def generate_billing do
    Stream.run(
      Stream.resource(fn -> Replicas.declarations_with_assocs(page: 1, page_size: 500) end,
                    fn collection ->
                      collection
                      |> process_billing(@async_billing)
                      if collection.total_pages <= collection.page_number do
                        {:halt, []}
                      else
                        Replicas.declarations_with_assocs(page: collection.page_number, page_size: 500)
                      end
                    end,
                    fn _ -> nil end
                    )
    )
  end

  def process_billing(collection, async \\ false)
  def process_billing(collection, true) do
    collection
    |> Flow.from_enumerable()
    |> Flow.partition()
    |> Flow.each(fn item -> Billings.create_billing(item) end)
    |> Flow.run()
  end
  def process_billing(collection, false) do
    collection
    |> Enum.each(fn item -> Billings.create_billing(item) end)
  end

  def generate_csv do
    header = ["edrpou", "name", "msp type", "0-5", "6-17", "18-39", "40-65", ">65", "initial", "gone green", "diff"]
    file = File.stream!("/tmp/capitation.csv", [:delayed_write, :utf8])
    Repo.transaction(fn ->
      Billings.get_billing_for_capitation
      |> Stream.chunk_by(fn x -> Enum.at(x, 0) end)
      |> Stream.map(&calcualte_total(&1, length(&1)))
      |> Stream.transform(0, &insert_header(&1, &2, header))
      |> Stream.flat_map(fn x -> x end)
      |> CSV.encode()
      |> Stream.into(file)
      |> Stream.run
    end, timeout: :infinity)
  end

  defp insert_header(row, count, header) do
    if count < 1 do
       {[[header]] ++ [row], count + 1}
    else
      {[row], count}
    end
  end

  defp calcualte_total(billings, 2) do
    b_one = Enum.at(billings, 0)
    b_two = Enum.at(billings, 1)
    [edrpou, name1, _, age1_1, age2_1, age3_1, age4_1, age5_1] = b_one
    [_, _, _, age1_2, age2_2, age3_2, age4_2, age5_2]          = b_two
    red_list = get_red_list_count(edrpou)
    total_billing = [
      edrpou, name1, "MSP Total", age1_1 + age1_2, age2_1 + age2_2, age3_1 + age3_2, age4_1 + age4_2, age5_1 + age5_2
    ]
    make_csv_line([b_one, b_two, total_billing], red_list)
  end

  defp calcualte_total(billings, 1) do
    billings = List.flatten(billings)
    [edrpou, name, mountain_group, age1, age2, age3, age4, age5] = billings
    red_list = get_red_list_count(edrpou)
    mountain_group = present?(mountain_group)
    temp_billing = [edrpou, name, !mountain_group, 0, 0, 0, 0, 0]
    total_billing = [edrpou, name, "MSP Total", age1, age2, age3, age4, age5]
    make_csv_line([billings, temp_billing, total_billing], red_list)
  end

  defp make_csv_line(billings, red_list) do
    billings
    |> Enum.reduce([], fn(b, acc) -> [list_to_map_strings(b) ++ red_list] ++ acc end)
    |> sort_by_mountain_group
  end

  defp list_to_map_strings(list) do
    Enum.map(list, fn v -> to_string_names(v) end)
  end

  def get_red_list_count(edrpou) do
    red_msps = RedLists.get_red_msp_by_edrpou(edrpou)
    ids = Enum.map(red_msps, &(Enum.at(&1, 0)))
    population_count = Enum.reduce(red_msps, 0, fn(rmsp, acc) -> acc + Enum.at(rmsp, 1) end)
    gone_green = RedLists.find_red_list_gone_green(ids)
    [population_count, gone_green, population_count - gone_green]
  end

  defp to_string_names(value) when is_boolean(value) or is_nil(value)  do
    bools = [true: "MSP Mountain", false: "MSP Regular", nil: "MSP Regular"]
    bools[value]
  end
  defp to_string_names(value), do: to_string(value)

  defp sort_by_mountain_group(list) do
    mapper =
      fn([_, _, group, _, _, _, _, _, _, _, _]) ->
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
