#!/bin/bash
set -euxo pipefail

source ./environment

psql -d $PGDATABASE -f ../database/create_view_pgr.sql
psql -d $PGDATABASE -f ../database/alter_table_component.sql