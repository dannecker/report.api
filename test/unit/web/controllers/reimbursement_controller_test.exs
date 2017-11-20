defmodule Report.Web.ReimbursementControllerTest do
  @moduledoc false

  use Report.Web.ConnCase
  import Report.Web.Router.Helpers
  alias Report.Connection

  describe "get stats" do
    test "legal_entity not found", %{conn: conn} do
      conn = get conn, reimbursement_path(conn, :index)
      assert %{"error" => %{"invalid" => [%{"entry" => "$.legal_entity_id"}]}} = json_response(conn, 422)
    end

    test "party not found", %{conn: conn} do
      %{id: legal_entity_id} = insert(:legal_entity)
      data = Poison.encode!(%{"client_id" => legal_entity_id})

      conn = Plug.Conn.put_req_header(conn, Connection.header(:consumer_metadata), data)
      conn = get conn, reimbursement_path(conn, :index)
      assert %{"error" => %{"invalid" => [%{"entry" => "$.party_id"}]}} = json_response(conn, 422)
    end

    test "legal_entity is not active", %{conn: conn} do
      %{id: legal_entity_id} = insert(:legal_entity, is_active: false)
      data = Poison.encode!(%{"client_id" => legal_entity_id})

      conn =
        conn
        |> Plug.Conn.put_req_header(Connection.header(:consumer_metadata), data)
        |> Plug.Conn.put_req_header(Connection.header(:consumer_id), Ecto.UUID.generate())
      conn = get conn, reimbursement_path(conn, :index)
      assert json_response(conn, 403)
    end

    test "employee not found", %{conn: conn} do
      %{id: legal_entity_id} = insert(:legal_entity)
      %{user_id: user_id} = insert(:party_user)

      data = Poison.encode!(%{"client_id" => legal_entity_id})

      conn =
        conn
        |> Plug.Conn.put_req_header(Connection.header(:consumer_metadata), data)
        |> Plug.Conn.put_req_header(Connection.header(:consumer_id), user_id)
      conn = get conn, reimbursement_path(conn, :index)
      assert json_response(conn, 403)
    end

    test "employee is not active", %{conn: conn} do
      legal_entity = insert(:legal_entity)
      %{user_id: user_id, party: party} =
        :party_user
        |> insert()
        |> Repo.preload(:party)
      insert(:employee, party: party, legal_entity: legal_entity, is_active: false)

      data = Poison.encode!(%{"client_id" => legal_entity.id})

      conn =
        conn
        |> Plug.Conn.put_req_header(Connection.header(:consumer_metadata), data)
        |> Plug.Conn.put_req_header(Connection.header(:consumer_id), user_id)
      conn = get conn, reimbursement_path(conn, :index)
      assert json_response(conn, 403)
    end

    test "no employee with matched legal_entity_id", %{conn: conn} do
      legal_entity = insert(:legal_entity)
      %{user_id: user_id, party: party} =
        :party_user
        |> insert()
        |> Repo.preload(:party)
      insert(:employee, party: party)

      data = Poison.encode!(%{"client_id" => legal_entity.id})

      conn =
        conn
        |> Plug.Conn.put_req_header(Connection.header(:consumer_metadata), data)
        |> Plug.Conn.put_req_header(Connection.header(:consumer_id), user_id)
      conn = get conn, reimbursement_path(conn, :index)
      assert json_response(conn, 403)
    end

    test "invalid period", %{conn: conn} do
      legal_entity = insert(:legal_entity)
      %{user_id: user_id, party: party} =
        :party_user
        |> insert()
        |> Repo.preload(:party)
      insert(:employee, party: party, legal_entity: legal_entity)

      data = Poison.encode!(%{"client_id" => legal_entity.id})

      conn =
        conn
        |> Plug.Conn.put_req_header(Connection.header(:consumer_metadata), data)
        |> Plug.Conn.put_req_header(Connection.header(:consumer_id), user_id)
      conn = get conn, reimbursement_path(conn, :index)
      assert %{"error" => %{"invalid" => [%{"entry" => "$.period"}]}} = json_response(conn, 422)
    end

    test "dispense input dates are not valid", %{conn: conn} do
      legal_entity = insert(:legal_entity)
      %{user_id: user_id, party: party} =
        :party_user
        |> insert()
        |> Repo.preload(:party)
      insert(:employee, party: party, legal_entity: legal_entity)

      data = Poison.encode!(%{"client_id" => legal_entity.id})

      conn =
        conn
        |> Plug.Conn.put_req_header(Connection.header(:consumer_metadata), data)
        |> Plug.Conn.put_req_header(Connection.header(:consumer_id), user_id)

      conn1 = get conn, reimbursement_path(conn, :index, %{
        "date_from_dispense" => to_string(Date.utc_today())
      })
      assert %{"error" => %{"invalid" => [%{"entry" => "$.period.dispense"}]}} = json_response(conn1, 422)

      conn2 = get conn, reimbursement_path(conn, :index, %{
        "date_from_dispense" => to_string(Date.add(Date.utc_today(), 2)),
        "date_to_dispense" => to_string(Date.utc_today())
      })
      assert %{"error" => %{"invalid" => [%{"entry" => "$.period.dispense"}]}} = json_response(conn2, 422)
    end

    test "request input dates are not valid", %{conn: conn} do
      %{id: medication_dispense_id, medication_request: medication_request} = insert(:medication_dispense)
      %{legal_entity: legal_entity} = Repo.preload(medication_request.employee, :legal_entity)
      %{user_id: user_id, party: party} =
        :party_user
        |> insert()
        |> Repo.preload(:party)
      insert(:employee, party: party, legal_entity: legal_entity)
      %{medication_id: medication_id} = insert(:medication_dispense_details,
        medication_dispense_id: medication_dispense_id
      )
      insert(:medication, id: medication_id)

      data = Poison.encode!(%{"client_id" => legal_entity.id})

      conn =
        conn
        |> Plug.Conn.put_req_header(Connection.header(:consumer_metadata), data)
        |> Plug.Conn.put_req_header(Connection.header(:consumer_id), user_id)

      conn1 = get conn, reimbursement_path(conn, :index, %{
        "date_to_request" => to_string(Date.utc_today())
      })
      assert %{"error" => %{"invalid" => [%{"entry" => "$.period.request"}]}} = json_response(conn1, 422)

      conn2 = get conn, reimbursement_path(conn, :index, %{
        "date_from_request" => to_string(Date.add(Date.utc_today(), 2)),
        "date_to_request" => to_string(Date.utc_today())
      })
      assert %{"error" => %{"invalid" => [%{"entry" => "$.period.request"}]}} = json_response(conn2, 422)
    end

    test "get stats by request period", %{conn: conn} do
      %{id: medication_dispense_id, medication_request: medication_request} = insert(:medication_dispense)
      %{legal_entity: legal_entity} = Repo.preload(medication_request.employee, :legal_entity)
      %{user_id: user_id, party: party} =
        :party_user
        |> insert()
        |> Repo.preload(:party)
      employee = insert(:employee, party: party, legal_entity: legal_entity)
      insert_details(medication_dispense_id)
      insert_details(medication_dispense_id)
      medication_request = insert(:medication_request, employee: employee)
      %{id: medication_dispense_id} = insert(:medication_dispense,
        medication_request: medication_request,
        legal_entity: legal_entity,
        party: party
      )
      insert_details(medication_dispense_id)
      insert_details(medication_dispense_id)
      Enum.each(1..8, fn _ ->
        insert(:medication_request, employee: employee)
      end)
      Enum.each(1..3, fn _ ->
        %{id: medication_dispense_id} = insert(:medication_dispense,
          medication_request: medication_request,
          legal_entity: legal_entity,
          party: party
        )

        insert_details(medication_dispense_id)
        insert_details(medication_dispense_id)
      end)

      data = Poison.encode!(%{"client_id" => legal_entity.id})

      conn =
        conn
        |> Plug.Conn.put_req_header(Connection.header(:consumer_metadata), data)
        |> Plug.Conn.put_req_header(Connection.header(:consumer_id), user_id)
      conn = get conn, reimbursement_path(conn, :index, %{
        "date_from_request" => to_string(Date.add(Date.utc_today(), -2)),
        "date_to_request" => to_string(Date.utc_today())
      })

      schema =
        "specs/schemas/reimbursement_report_response.json"
        |> File.read!()
        |> Poison.decode!()

      resp = json_response(conn, 200)
      :ok = NExJsonSchema.Validator.validate(schema, resp)
      assert 10 == length(resp["data"])
    end

    test "get stats by dispense period", %{conn: conn} do
      %{id: medication_dispense_id, medication_request: medication_request} = insert(:medication_dispense)
      %{legal_entity: legal_entity} = Repo.preload(medication_request.employee, :legal_entity)
      %{user_id: user_id, party: party} =
        :party_user
        |> insert()
        |> Repo.preload(:party)
      insert(:employee, party: party, legal_entity: legal_entity)
      %{medication_id: medication_id} = insert(:medication_dispense_details,
        medication_dispense_id: medication_dispense_id
      )
      insert(:medication, id: medication_id)

      data = Poison.encode!(%{"client_id" => legal_entity.id})

      conn =
        conn
        |> Plug.Conn.put_req_header(Connection.header(:consumer_metadata), data)
        |> Plug.Conn.put_req_header(Connection.header(:consumer_id), user_id)
      conn = get conn, reimbursement_path(conn, :index, %{
        "date_from_dispense" => to_string(Date.add(Date.utc_today(), -2)),
        "date_to_dispense" => to_string(Date.utc_today())
      })

      schema =
        "specs/schemas/reimbursement_report_response.json"
        |> File.read!()
        |> Poison.decode!()

      resp = json_response(conn, 200)
      :ok = NExJsonSchema.Validator.validate(schema, resp)
      assert 1 == length(resp["data"])
    end

    test "get stats by dispense and request periods", %{conn: conn} do
      legal_entity = insert(:legal_entity, type: "PHARMACY")
      %{id: medication_dispense_id} = insert(:medication_dispense, legal_entity: legal_entity)
      %{user_id: user_id, party: party} =
        :party_user
        |> insert()
        |> Repo.preload(:party)
      insert(:employee, party: party, legal_entity: legal_entity)
      %{medication_id: medication_id} = insert(:medication_dispense_details,
        medication_dispense_id: medication_dispense_id
      )
      insert(:medication, id: medication_id)

      data = Poison.encode!(%{"client_id" => legal_entity.id})

      conn =
        conn
        |> Plug.Conn.put_req_header(Connection.header(:consumer_metadata), data)
        |> Plug.Conn.put_req_header(Connection.header(:consumer_id), user_id)
      conn = get conn, reimbursement_path(conn, :index, %{
        "date_from_request" => to_string(Date.add(Date.utc_today(), -2)),
        "date_to_request" => to_string(Date.utc_today()),
        "date_from_dispense" => to_string(Date.add(Date.utc_today(), -2)),
        "date_to_dispense" => to_string(Date.utc_today())
      })

      schema =
        "specs/schemas/reimbursement_report_response.json"
        |> File.read!()
        |> Poison.decode!()

      resp = json_response(conn, 200)
      :ok = NExJsonSchema.Validator.validate(schema, resp)
      assert 1 == length(resp["data"])
    end
  end

  describe "get csv data" do
    test "invalid period", %{conn: conn} do
      conn = get conn, reimbursement_path(conn, :download)
      assert %{
        "error" => %{
          "invalid" => [
            %{"entry" => "$.date_from_dispense"},
            %{"entry" => "$.date_to_dispense"}
          ]
        }
      } = json_response(conn, 422)
    end

    test "dispense input dates are not valid", %{conn: conn} do
      conn1 = get conn, reimbursement_path(conn, :download, %{
        "date_from_dispense" => to_string(Date.utc_today()),
        "date_to_dispense" => to_string(Date.add(Date.utc_today(), -1))
      })
      assert %{"error" => %{"invalid" => [%{"entry" => "$.date_from_dispense"}]}} = json_response(conn1, 422)
    end

    test "get stats by dispense period", %{conn: conn} do
      %{id: medication_dispense_id, medication_request: medication_request} = insert(:medication_dispense,
        status: "PROCESSED"
      )
      legal_entity = insert(:legal_entity, id: medication_request.legal_entity_id)
      insert(:employee, legal_entity: legal_entity)
      %{medication_id: medication_id} = insert(:medication_dispense_details,
        medication_dispense_id: medication_dispense_id
      )
      insert(:medication, id: medication_id)
      %{medication_id: medication_id} = insert(:medication_dispense_details,
        medication_dispense_id: medication_dispense_id
      )
      insert(:medication, id: medication_id)

      insert(:innm_dosage_ingredient, parent_id: medication_request.medication_id)
      insert(:innm_dosage_ingredient, parent_id: medication_request.medication_id, is_primary: false)

      conn = get conn, reimbursement_path(conn, :download, %{
        "date_from_dispense" => to_string(Date.add(Date.utc_today(), -2)),
        "date_to_dispense" => to_string(Date.utc_today())
      })
      assert resp = response(conn, 200)
      assert response_content_type(conn, :csv) =~ "charset=utf-8"
      result = resp |> String.split("\r\n") |> CSV.decode!(headers: false) |> Enum.take(3)
      assert 3 == length(result)
    end
  end

  defp insert_details(medication_dispense_id) do
    %{medication_id: medication_id} = insert(:medication_dispense_details,
      medication_dispense_id: medication_dispense_id
    )
    insert(:medication, id: medication_id)
  end
end
