#!/bin/bash
set -euxo pipefail

source ./environment

psql -d $PGDATABASE -f ../database/alter_tables_pk_fk.sql
