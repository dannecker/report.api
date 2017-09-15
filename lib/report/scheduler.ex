defmodule Report.Scheduler do
    @moduledoc false
    use Quantum.Scheduler,
      otp_app: :report_api
  end
