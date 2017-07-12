#!/bin/bash

psql -h 0.0.0.0 -U postgres -d report_test -f regions.sql
psql -h 0.0.0.0 -U postgres -d report_test -f districts.sql
psql -h 0.0.0.0 -U postgres -d report_test -f settlements.sql
psql -h 0.0.0.0 -U postgres -d report_test -f settlements_fix_19062017.sql
psql -h 0.0.0.0 -U postgres -d report_test -f settlements_fix_22062017.sql
