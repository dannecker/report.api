defmodule Report.GandalfCaller do
  @moduledoc false
  require Logger

  def make_decision(params) do
    config = Confex.get_env(:report_api, :gandalf)
    params
    |> Poison.encode!()
    |> http_call(config, [retry: 5, timeout: 1000])
    |> parse_resp()
  end

  defp http_call(_, _, [retry: 0, timeout: _]), do: {:error, "Gandalf max retries exceeded"}
  defp http_call(body, config, [retry: retry, timeout: timeout]) do
    case HTTPoison.post(config[:url], body,
                        headers(config), recv_timeout: 30_000,
                        hackney: [pool: :default], ssl: [versions: [:"tlsv1.2"]]) do
      {:ok, %HTTPoison.Response{status_code: status, body: body}} when status > 299 ->
        Logger.error fn -> "#{config[:url]}, #{body}" end
        {:error, "Gandalf error #{status} #{body}"}
      {:ok, %HTTPoison.Response{status_code: status, body: body}} when status < 299 ->
        %{status_code: status, body: body}
      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error fn -> "#{config[:url]}, #{reason}" end
        :timer.sleep(timeout)
        http_call(body, config, [retry: retry - 1, timeout: timeout + 1000])
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
    {:ok, %{id: id, decision: decision}}
  end
end
