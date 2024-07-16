#!/bin/bash
set -euo pipefail

PGDATABASE=cnrt2
PGUSER=romulus

# sudo apt install postgis postgresql-pgrouting gdal-bin

sudo -u postgres createdb $PGDATABASE -O $PGUSER
sudo -u postgres psql $PGDATABASE -c "CREATE EXTENSION postgis WITH SCHEMA public;"
sudo -u postgres psql $PGDATABASE -c "CREATE EXTENSION pgrouting WITH SCHEMA public;"