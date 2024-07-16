#!/bin/bash
set -euxo pipefail

source ./environment

COMMON_OPTS="-f PostgreSQL -overwrite -t_srs EPSG:3163"
CONNSTRING="dbname=$PGDATABASE user=$PGUSER"
DATA=../import

echo $COMMON_OPTS PG:$CONNSTRING;
echo "Script à exécuter depuis le dossier scripts/ du dépôt GitHub"
read -p "Chargement des données sources dans PostgreSQL. [Appuyer pour continuer]" </dev/tty

# see documentation

ogr2ogr $COMMON_OPTS -lco FID=objectid -nln dittt_noeuds PG:"$CONNSTRING"\
  /vsizip/$DATA/Réseau_routier_noeuds_BDROUTE-NC.zip
ogr2ogr $COMMON_OPTS -lco FID=objectid -nlt PROMOTE_TO_MULTI -nln dittt_segments PG:"$CONNSTRING"\
  /vsizip/$DATA/Réseau_routier_segments_BDROUTE-NC.zip
psql -d $PGDATABASE -f ../database/create_table_denominations.sql
psql -d $PGDATABASE -c "DELETE FROM dittt_denominations;"
psql -d $PGDATABASE -c "\COPY dittt_denominations FROM '$DATA/Réseau_routier_denominations_BDROUTE-NC.csv' DELIMITER ',' CSV HEADER;"

ogr2ogr $COMMON_OPTS -lco FID=objectid -nln dimenc_centres PG:"$CONNSTRING"\
  /vsizip/$DATA/Exploitation_minière_centres_miniers.zip
ogr2ogr $COMMON_OPTS -lco FID=objectid -nln dimenc_usines PG:"$CONNSTRING"\
  /vsizip/$DATA/Exploitation_minière_usines_metallurgiques.zip
ogr2ogr $COMMON_OPTS -lco FID=objectid -nlt PROMOTE_TO_MULTI -lco PRECISION=NO -nln bdadmin_communes PG:"$CONNSTRING"\
  /vsizip/$DATA/Limites_administratives_terrestres_communes.zip
ogr2ogr $COMMON_OPTS -lco "FID=fid_iris" -nlt PROMOTE_TO_MULTI -nln cnrt_iris PG:"$CONNSTRING"\
  /vsizip/$DATA/CNRT_iris_2014.zip
ogr2ogr $COMMON_OPTS -lco "FID=fid_etab"  -nln dass_etabs_sante PG:"$CONNSTRING"\
  /vsizip/$DATA/Situation_etablissements_sante.zip
# Warning 1: Field 'contact_tel' already exists. Renaming it as 'contact_tel2'


