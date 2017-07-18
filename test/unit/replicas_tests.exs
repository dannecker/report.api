defmodule Report.Replica.ReplicasTest do
  @moduledoc false
  use Report.DataCase, async: true
  import Report.Factory
  alias Report.Replica.Replicas
  alias Report.Repo

  describe "Replicas API" do
    setup do
      declarations = for _ <- 0..14, do: make_declaration_with_all()
      %{declarations: declarations}
    end

    test "list_declarations/0" do
      declarations = Replicas.list_declarations()
      assert length(declarations) == 15
    end

    test "stream_declarations_beetween/0", %{declarations: declarations} do
      stream = Replicas.stream_declarations_beetween(
          List.first(declarations).inserted_at,
          List.last(declarations).inserted_at
      )
      {:ok, declarations} = Repo.transaction(fn() ->
        Enum.to_list(stream)
      end)
      assert length(declarations) == 15
    end

    test "get_oldest_declaration_date/0", %{declarations: declarations} do
      assert List.first(declarations).inserted_at == Replicas.get_oldest_declaration_date()
    end
  end
end
