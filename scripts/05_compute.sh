#!/bin/bash
set -euxo pipefail

source ./environment

psql -c "\timing on" -d $PGDATABASE -f ../database/insert_table_desserte_dass_etabs_sante.sql
psql -c "\timing on" -d $PGDATABASE -f ../database/insert_table_desserte_dimenc_centres.sql
psql -c "\timing on" -d $PGDATABASE -f ../database/insert_table_desserte_dimenc_usines.sql

psql -c "\timing on" -d $PGDATABASE -f ../database/insert_table_desserte_aggregate_dass_etabs_sante.sql
psql -c "\timing on" -d $PGDATABASE -f ../database/insert_table_desserte_aggregate_dimenc_centres.sql
psql -c "\timing on" -d $PGDATABASE -f ../database/insert_table_desserte_aggregate_dimenc_usines.sql
