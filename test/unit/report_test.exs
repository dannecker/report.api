defmodule ReportTest do
  use ExUnit.Case
  doctest Report

  test "load_from_system_env/1 resolves :system tuples" do
    System.put_env("MY_TEST_ENV", "test_env_value")
    on_exit(fn ->
      System.delete_env("MY_TEST_ENV")
    end)

    assert {:ok, [
      my_conf: "test_env_value",
      other_conf: "persisted"
    ]} == Report.load_from_system_env([my_conf: {:system, "MY_TEST_ENV"}, other_conf: "persisted"])
  end

  describe "configure_log_level/1" do
    test "tolerates nil values" do
      assert :ok == Report.configure_log_level(nil)
    end

    test "raises on invalid LOG_LEVEL" do
      assert_raise ArgumentError, fn ->
        Report.configure_log_level("super_critical")
      end

      assert_raise ArgumentError, fn ->
        Report.configure_log_level(:not_a_string)
      end
    end

    test "configures log level" do
      :ok = Report.configure_log_level("debug")
    end
  end
end
