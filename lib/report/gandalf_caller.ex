defmodule Report.GandalfCaller do
  @moduledoc false
  require Logger

  def make_decision(params) do
    config = Confex.get_env(:report_api, :gandalf)
    params
    |> Poison.encode!()
    |> http_call(config)
    |> parse_resp()
  end

  defp http_call(body, config) do
    case HTTPoison.post(config[:url], body, headers(config), [recv_timeout: 30_000, hackney: [pool: :default]]) do
      {:ok, %HTTPoison.Response{status_code: status, body: body}} when status > 299 ->
        Logger.error fn -> "#{config[:url]}, #{body}" end
        raise "Gandalf error #{status} #{body}"
      {:ok, %HTTPoison.Response{status_code: status, body: body}} when status < 299 ->
        %{status_code: status, body: body}
      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error fn -> "#{config[:url]}, #{reason}" end
        raise to_string(reason)
    end
  end

  defp headers(config) do
    [
      {"Content-Type", "application/json"},
      {"Authorization", "Basic #{auth_token(config)}"},
      {"X-Application", "58eca20fe79e8563e803dc18"}
    ]
  end

  defp auth_token(config) do
    [config[:user], config[:password]]
      |> Enum.join(":")
      |> Base.encode64
  end

  defp parse_resp(%{body: body}) do
    %{"data" => %{"_id" => id, "final_decision" => decision}} = Poison.decode!(body)
    %{id: id, decision: decision}
  end
end
