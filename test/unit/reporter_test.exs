defmodule Report.ReporterTest do
  @moduledoc false
  use Report.DataCase, async: true
  import Report.Factory
  alias Report.Billings
  alias Report.Reporter

  describe "Capitation report" do
    setup do
      declarations = for _ <- 0..14, do: make_declaration_with_all()
      :ok
    end

    test "capitation/0" do
      # Reporter.capitation
    end
  end
end
