# Élaboration d'une matrice de desserte en Nouvelle-Calédonie

Ce document décrit le calcul du temps de trajet par la route entre les IRIS et les sites miniers (mines et usines) de Nouvelle-Calédonie en croisant les données suivantes :

- Le réseau routier fourni par la [DITTT](https://dittt.gouv.nc/).
- Les sites miniers fournis par la [DIMENC](https://dimenc.gouv.nc/).
- Les IRIS proposés par l'[ISEE](https://www.isee.nc) pour le projet [CNRT Mine et Territoires - Impact de la mine sur l'évolution des territoires](https://cnrt.nc/mine-et-territoire/).

Le but est d'obtenir une _matrice de desserte_ où les durées trajets entre les sites et les nœuds du réseau routier sont agrégées par IRIS afin d'estimer la proximité par la route entre les mines et les IRIS.
Un extrait indicatif (les données complètes sont fournies dans le dossier [dist](dist/)) de dix durées de trajets vers les usines est donné ci-après.
L'avant-dernière ligne indique qu'il faut entre 70 et 147 minutes, avec une durée médiane de 105 minutes et une moyenne de 108 minutes, pour aller de l'usine _KNS - Koniambo_ (dite _usine nord_) aux noeuds routiers situés dans l'IRIS 2306 _Aoupinié - Goro Darawé_ sur la commune de Ponérihouen.

```raw
 Code IRIS |              Libellé IRIS              | Code commune | Société |   Site   | Durée minimum | Durée médiane | Durée moyenne | Durée maximum 
-----------+----------------------------------------+--------------+---------+----------+---------------+---------------+---------------+---------------
 2104      | Ondémia Port Laguerre                  |        98821 | VALE NC | Goro     |            92 |            98 |            99 |           118
 1825      | Doniambo - Montagne coupée - Montravel |        98818 | VALE NC | Goro     |            85 |            86 |            87 |            95
 3201      | Waho Touaourou Goro                    |        98832 | VALE NC | Goro     |             8 |            35 |            33 |            50
 1828      | Portes de Fer - Nord                   |        98818 | KNS     | Koniambo |           190 |           191 |           191 |           193
 3101      | Voh village - Gatope                   |        98831 | KNS     | Koniambo |             0 |            10 |            10 |            23
 1706      | Robinson Sud                           |        98817 | VALE NC | Goro     |            77 |            79 |            79 |            85
 2102      | Scheffleras                            |        98821 | SLN     | Doniambo |            18 |            19 |            19 |            29
 1836      | PK 7 Est                               |        98818 | KNS     | Koniambo |           188 |           189 |           189 |           191
 2306      | Aoupinié - Goro Darawé                 |        98823 | KNS     | Koniambo |            70 |           105 |           108 |           147
 1702      | Yahoué Sud                             |        98817 | VALE NC | Goro     |            82 |            83 |            83 |            88
```

## Import des données

Ici, on considère les versions suivantes téléchargées le 2024-06-28.

- [BDROUTE-NC](https://georep-dtsi-sgt.opendata.arcgis.com/maps/d3915082450a4405bb30dda99e19bc61/about), version du 14 juin 2023, mise à jour le 11 mars 2024 ;
- [Exploitation minière](https://georep-dtsi-sgt.opendata.arcgis.com/maps/464a23302d6a473a9188ab8e26684206/about), version du 8 juin 2010, mise à jour le 31 mars 2017 ;
- [Limites administratives terrestres](https://georep-dtsi-sgt.opendata.arcgis.com/maps/e1d853903cc64d40af7fbb5ee57e3029/about), version du 23 décembre 2009, mise à jour le 2 mars 2022.
- [IRIS UNC 2014](dist/cnrt_iris_2014.zip), ces fichiers sont fournis par le projet CNRT dans le présent dépôt.

```bash
PGDATABASE=cnrt2
PGUSER=romulus
sudo apt install postgis postgresql-pgrouting gdal-bin

sudo -u postgres createdb $PGDATABASE -O $PGUSER
sudo -u postgres psql $PGDATABASE -c "CREATE EXTENSION postgis WITH SCHEMA public;"
sudo -u postgres psql $PGDATABASE -c "CREATE EXTENSION pgrouting WITH SCHEMA public;"

wget --output-document data/Réseau_routier_noeuds_BDROUTE-NC.zip "https://opendata.arcgis.com/api/v3/datasets/d3915082450a4405bb30dda99e19bc61_0/downloads/data?format=shp&spatialRefId=3163"
wget --output-document data/Réseau_routier_segments_BDROUTE-NC.zip "https://opendata.arcgis.com/api/v3/datasets/d3915082450a4405bb30dda99e19bc61_6/downloads/data?format=shp&spatialRefId=3163"
wget --output-document data/Réseau_routier_denominations_BDROUTE-NC.csv "https://opendata.arcgis.com/api/v3/datasets/d3915082450a4405bb30dda99e19bc61_7/downloads/data?format=csv&spatialRefId=3163"
wget --output-document data/Exploitation_minière_usines_metallurgiques.zip "https://opendata.arcgis.com/api/v3/datasets/464a23302d6a473a9188ab8e26684206_0/downloads/data?format=shp&spatialRefId=3163"
wget --output-document data/Exploitation_minière_centres_miniers.zip "https://opendata.arcgis.com/api/v3/datasets/464a23302d6a473a9188ab8e26684206_1/downloads/data?format=shp&spatialRefId=data/3163"
wget --output-document data/Limites_administratives_terrestres_communes.zip "https://opendata.arcgis.com/api/v3/datasets/e1d853903cc64d40af7fbb5ee57e3029_0/downloads/data?format=shp&spatialRefId=3data/163data/"
wget --output-document data/CNRT_iris_2014.zip "https://github.com/romulusFR/desserte_NC/raw/main/dist/cnrt_iris_2014.zip"
wget --output-document data/Situation_etablissements_sante.zip "https://data.gouv.nc/api/explore/v2.1/catalog/datasets/situation_etablissements_sante/exports/shp?lang=fr&timezone=Pacific%2FNoumea"

ogr2ogr -f "PostgreSQL" PG:"dbname=$PGDATABASE user=$PGUSER" -overwrite -t_srs "EPSG:3163" -lco FID=objectid \
  /vsizip/data/Réseau_routier_noeuds_BDROUTE-NC.zip -nln dittt_noeuds
ogr2ogr -f "PostgreSQL" PG:"dbname=$PGDATABASE user=$PGUSER" -overwrite -t_srs "EPSG:3163" -lco FID=objectid -nlt PROMOTE_TO_MULTI\
  /vsizip/data/Réseau_routier_segments_BDROUTE-NC.zip -nln dittt_segments
psql -d $PGDATABASE -f dist/Réseau_routier_denominations_BDROUTE-NC.sql
psql -d $PGDATABASE -c "\COPY dittt_denominations FROM 'data/Réseau_routier_denominations_BDROUTE-NC.csv' DELIMITER ',' CSV HEADER;"

ogr2ogr -f "PostgreSQL" PG:"dbname=$PGDATABASE user=$PGUSER" -overwrite -t_srs "EPSG:3163" -lco FID=objectid \
  /vsizip/data/Exploitation_minière_centres_miniers.zip -nln dimenc_centres
ogr2ogr -f "PostgreSQL" PG:"dbname=$PGDATABASE user=$PGUSER" -overwrite -t_srs "EPSG:3163" -lco FID=objectid \
  /vsizip/data/Exploitation_minière_usines_metallurgiques.zip -nln dimenc_usines
ogr2ogr -f "PostgreSQL" PG:"dbname=$PGDATABASE user=$PGUSER" -overwrite -t_srs "EPSG:3163" -nlt PROMOTE_TO_MULTI -lco PRECISION=NO -lco FID=objectid\
  /vsizip/data/Limites_administratives_terrestres_communes.zip -nln bdadmin_communes
ogr2ogr -f "PostgreSQL" PG:"dbname=$PGDATABASE user=$PGUSER" -overwrite -t_srs "EPSG:3163" -lco "FID=fid_iris" -nlt PROMOTE_TO_MULTI\
  /vsizip/data/CNRT_iris_2014.zip -nln cnrt_iris
ogr2ogr -f "PostgreSQL" PG:"dbname=$PGDATABASE user=$PGUSER" -overwrite -t_srs "EPSG:3163" -lco "FID=fid_etab"\
  /vsizip/data/Situation_etablissements_sante.zip -nln dass_etabs_sante
# Warning 1: Field 'contact_tel' already exists. Renaming it as 'contact_tel2'

# pour régénérer le schéma SQL en cas de changement avec <https://csvkit.readthedocs.io/en/latest/>
#  csvsql --dialect postgresql --delimiter ","  data/Réseau_routier_denominations_BDROUTE-NC.csv --tables dittt_denominations
```

## Calcul des trajets

## Export des résultats
