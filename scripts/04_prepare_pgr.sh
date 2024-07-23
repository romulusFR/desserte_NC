#!/bin/bash
set -euxo pipefail

source ./environment

psql -c "\timing on" -d $PGDATABASE -f ../database/create_view_pgr.sql
psql -d $PGDATABASE -f ../database/alter_table_component.sql
psql -d $PGDATABASE -f ../database/alter_table_noeud_dittt_ref.sql
psql -d $PGDATABASE -f ../database/create_table_desserte.sql


