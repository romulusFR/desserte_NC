#!/bin/bash
set -euxo pipefail

source ./environment


psql -c "\timing on" -d $PGDATABASE -c "\COPY (SELECT iris_code, iris_libelle, poi_type, poi_id, poi_name, round(minimum, 2) as minimum, round(mediane, 2) as mediane, round(moyenne, 2) as moyenne, round(maximum, 2) as maximum FROM desserte_aggregate_iris WHERE poi_type IN ('dimenc_usines', 'dimenc_centres')) TO '../dist/desserte_mine_iris.csv' WITH (FORMAT CSV, DELIMITER ',', HEADER ON, NULL 'NULL');"

psql -c "\timing on" -d $PGDATABASE -c "\COPY (SELECT iris_code, iris_libelle, poi_type, poi_id, poi_name, round(minimum, 2) as minimum, round(mediane, 2) as mediane, round(moyenne, 2) as moyenne, round(maximum, 2) as maximum FROM desserte_aggregate_iris WHERE poi_type IN ('dass_etabs_sante')) TO '../dist/desserte_etabs_sante_iris.csv' WITH (FORMAT CSV, DELIMITER ',', HEADER ON, NULL 'NULL');"

python3 pivot.py