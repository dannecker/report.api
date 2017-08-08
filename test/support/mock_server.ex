defmodule Report.MockServer do
  @moduledoc false

  use Plug.Router

  plug :match
  plug Plug.Parsers, parsers: [:json],
                     pass:  ["application/json"],
                     json_decoder: Poison
  plug :dispatch

  post "/media_content_storage_secrets" do
    %{"secret" => %{"bucket" => bucket, "resource_id" => id, "resource_name" => name}} = conn.body_params
    url = "http://localhost:4040/#{bucket}/#{id}/#{name}?authuser=1"
    Plug.Conn.send_resp(conn, 200, Poison.encode!(%{"data" => %{"secret_url" => url}}))
  end

  post "/validate_signed_entity" do
    Plug.Conn.send_resp(conn, 200, Poison.encode!(%{"data" => %{"is_valid" => true}}))
  end
end
