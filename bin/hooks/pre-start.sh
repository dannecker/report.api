#!/bin/sh
# `pwd` should be /opt/report
APP_NAME="report_api"

if [ "${DB_MIGRATE}" == "true" ]; then
  echo "[WARNING] Migrating database!"
  ./bin/$APP_NAME command "Elixir.Report.ReleaseTasks" migrate!
fi;
