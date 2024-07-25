# Scripts de reproduction des calculs

Les scripts suivants sont fournis pour exécuter à nouveau l'ensemble des calculs.
Le fichier [environment](environment) contient variables de configuration de l'accès à la base PostgreSQL en local via socket Unix.
Les scripts sont exécutés dans l'ordre qui suit :

- `00_createdb.sh` Création de la base PostgreSQL, _optionnel_.
- `01_download.sh` Téléchargement des données sources, liens valables le 2024-07-16.
- `02_import_pg.sh` Chargement des données dans la base PostgreSQL.
- `03_cleaning.sh` Ajout de clefs primaires et étrangères.
- `04_prepare_pgr.sh` Création de la vue matérialisée pour `pgRouting` et modifications préparatoires des tables pour les calculs des dessertes.
- `05_compute.sh` Calcul les dessertes avec `pgRouting` et stockage des résultats dans des tables.
- `06_export.sh` Génération les fichiers CSV de la matrice de desserte entre IRIS et points d'intérêt : un fichier pour les sites DIMENC et un pour les établissements de santé. Génère aussi les versions pivotées horizontalemement.
