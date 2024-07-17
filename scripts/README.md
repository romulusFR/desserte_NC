# Scripts de création de la base

Les scripts suivants sont fournis pour exécuter à nouveau l'ensemble des calculs.
Le fichier [environment](environment) contient variables de configuration de l'accès à la base PostgreSQL en local via socket Unix.
Les scripts sont exécutés dans l'ordre.

- `00_createdb.sh` création de la base PostgreSQL.
- `01_download.sh` téléchargement des données sources, liens valables le 2024-07-16.
- `02_import_pg.sh` chargement des données dans la base PostgreSQL.
- `03_cleaning.sh` ajout de clefs primaires et étrangères.
- `04_prepare_pgr.sh` création de la vue matérialisée pour pgRouting.
