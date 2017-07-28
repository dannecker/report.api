{:ok, _} = Application.ensure_all_started(:ex_machina)
ExUnit.configure(exclude: [pending: true])
ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Report.Repo, :manual)

defmodule GandalfMockServer do
  use Plug.Router
  plug :match
  plug :dispatch

  post "/" do
    test_resp = """
    {"meta":{"code":200},
      "data":{"_id":"597b3db3e79e854e482b0619","table":{"_id":"59775b4ee79e854e482b045b",
      "title":"Capitation: Compensation Group","description":"Capitation: Compensation Group calculation logic",
      "matching_type":"decision","variant":{"_id":"59775b4ee79e854e482b045a",
      "title":"Capitation: Compensation Group",
      "description":"Capitation: Compensation Group calculation logic"}},
      "application":"58eca20fe79e8563e803dc18","title":"Mountain adult+",
      "description":null,"final_decision":"G9","request":{"mountain_group":false,"age":68},
      "created_at":"2017-07-28T13:35:47+0000","updated_at":"2017-07-28T13:35:47+0000"}}
    """
    conn
    |> put_resp_header("Content-Type", "text/xml")
    |> send_resp(200, test_resp)
  end
end
{:ok, _} = Plug.Adapters.Cowboy.http GandalfMockServer, [], port: 4000
