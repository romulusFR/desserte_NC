#!/bin/bash
set -euxo pipefail

source ./environment

# si besoin, ici installation via les dépôts debian/ubuntu, voir 
# <https://www.postgresql.org/download/linux/>
# sudo apt install postgis postgres postgresql-pgrouting gdal-bin

# si besoin, mettre à jour le fichier /etc/postgresql/16/main/postgresql.conf
# avec les paramètres inspirés du fichier database/postgresql.conf

sudo -u postgres createdb $PGDATABASE -O $PGUSER
sudo -u postgres psql $PGDATABASE -c "CREATE EXTENSION postgis WITH SCHEMA public;"
sudo -u postgres psql $PGDATABASE -c "CREATE EXTENSION pgrouting WITH SCHEMA public;"