# Scripts de création de la base

Les scripts suivants sont fournis pour exécuter à nouveau l'ensemble des calculs.
Ils sont exécutés dans l'ordre.

- `environment` variables de configuration de l'accès à la base PostgreSQL en local via socket Unix.
- `00_createdb.sh` création de la base PostgreSQL.
- `01_download.sh` téléchargement des données sources, liens valables le 2024-07-16.
- `02_import_pg.sh` chargement des données dans la base PostgreSQL.
