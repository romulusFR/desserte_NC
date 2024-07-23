#!/bin/bash
set -euxo pipefail

source ./environment

psql -d $PGDATABASE -f ../database/insert_table_desserte_dass_etabs_sante.sql
psql -d $PGDATABASE -f ../database/insert_table_desserte_dimenc_centres.sql
psql -d $PGDATABASE -f ../database/insert_table_desserte_dimenc_usines.sql

psql -d $PGDATABASE -f ../database/insert_table_desserte_aggregate_dass_etabs_sante.sql
psql -d $PGDATABASE -f ../database/insert_table_desserte_aggregate_dimenc_centres.sql
psql -d $PGDATABASE -f ../database/insert_table_desserte_aggregate_dimenc_usines.sql
