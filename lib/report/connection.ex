defmodule Report.Connection do
  @moduledoc """
  Plug.Conn helpers
  """
  require Logger

  @header_consumer_id "x-consumer-id"
  @header_consumer_metadata "x-consumer-metadata"

  def header(:consumer_id), do: @header_consumer_id
  def header(:consumer_metadata), do: @header_consumer_metadata

  def get_user_id(headers) do
    get_header(headers, @header_consumer_id)
  end

  def get_legal_entity_id(headers) do
    headers
    |> get_client_metadata()
    |> decode_client_metadata()
  end

  def get_client_metadata(headers) do
    get_header(headers, @header_consumer_metadata)
  end

  defp decode_client_metadata(nil), do: nil
  defp decode_client_metadata(metadata) do
    metadata
    |> Poison.decode()
    |> process_decoded_data()
  end

  defp process_decoded_data({:ok, data}), do: Map.get(data, "client_id")
  defp process_decoded_data(_error), do: nil

  def get_header(headers, header) when is_list(headers) do
    list = for {k, v} <- headers, k == header, do: v
    List.first(list)
  end
end
