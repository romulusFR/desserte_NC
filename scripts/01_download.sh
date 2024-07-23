#!/bin/bash
set -euxo pipefail

DATA="../import"

echo "Script à exécuter depuis le dossier scripts/ du dépôt GitHub"
read -p "Téléchargement des données sources. [Appuyer pour continuer]" </dev/tty

wget --output-document $DATA/Réseau_routier_noeuds_BDROUTE-NC.zip "https://opendata.arcgis.com/api/v3/datasets/d3915082450a4405bb30dda99e19bc61_0/downloads/data?format=shp&spatialRefId=3163"
wget --output-document $DATA/Réseau_routier_segments_BDROUTE-NC.zip "https://opendata.arcgis.com/api/v3/datasets/d3915082450a4405bb30dda99e19bc61_6/downloads/data?format=shp&spatialRefId=3163"
wget --output-document $DATA/Réseau_routier_denominations_BDROUTE-NC.csv "https://opendata.arcgis.com/api/v3/datasets/d3915082450a4405bb30dda99e19bc61_7/downloads/data?format=csv&spatialRefId=3163"
wget --output-document $DATA/Exploitation_minière_centres_miniers.zip "https://opendata.arcgis.com/api/v3/datasets/464a23302d6a473a9188ab8e26684206_0/downloads/data?format=shp&spatialRefId=3163"
wget --output-document $DATA/Exploitation_minière_usines_metallurgiques.zip "https://opendata.arcgis.com/api/v3/datasets/464a23302d6a473a9188ab8e26684206_1/downloads/data?format=shp&spatialRefId=3163"
wget --output-document $DATA/Limites_administratives_terrestres_communes.zip "https://opendata.arcgis.com/api/v3/datasets/e1d853903cc64d40af7fbb5ee57e3029_0/downloads/data?format=shp&spatialRefId=3163"
wget --output-document $DATA/CNRT_iris_2014.zip "https://github.com/romulusFR/desserte_NC/raw/main/dist/cnrt_iris_2014.zip"
wget --output-document $DATA/Situation_etablissements_sante.zip "https://data.gouv.nc/api/explore/v2.1/catalog/datasets/situation_etablissements_sante/exports/shp?lang=fr&timezone=Pacific%2FNoumea"