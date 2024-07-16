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


Dans une base PostgreSQL supposée déjà créée et configurée, on exécute les scripts [01_download.sh](scripts/01_download.sh) puis [02_import_pg.sh](scripts/02_import_pg.sh) qui vont télécharger les données puis les importer.
À l'issue de l'exécution, les tables suivantes sont créées dans la base PostgreSQL, voir le fichier [infos.sql](database/infos.sql) :

```raw
dittt_noeuds
dittt_segments
dittt_denominations
dimenc_centres
dimenc_usines
bdadmin_communes
cnrt_iris
dass_etabs_sante
```

## Calcul des trajets

## Export des résultats

## Annexe

### Environnement utilisé

```bash
neofetch  --stdout
# romulus@cypher 
# -------------- 
# OS: Ubuntu 23.04 x86_64 
# Host: Precision 5470 
# Kernel: 6.2.0-39-generic 
# Uptime: 2 hours, 28 mins 
# Packages: 3817 (dpkg), 31 (snap) 
# Shell: bash 5.2.15 
# Resolution: 1920x1200, 2560x1440 
# DE: GNOME 44.3 
# WM: Mutter 
# WM Theme: Adwaita 
# Theme: Yaru-dark [GTK2/3] 
# Icons: Yaru [GTK2/3] 
# Terminal: tmux 
# CPU: 12th Gen Intel i7-12800H (20) @ 4.700GHz 
# GPU: NVIDIA RTX A1000 Laptop GPU 
# GPU: Intel Alder Lake-P 
# Memory: 8200MiB / 31695MiB 

ogrinfo  --version
# GDAL 3.6.2, released 2023/01/02

psql cnrt2 -c "select version()" 
# PostgreSQL 16.2 (Ubuntu 16.2-1.pgdg23.04+1) on x86_64-pc-linux-gnu, compiled by gcc (Ubuntu 12.3.0-1ubuntu1~23.04) 12.3.0, 64-bit

psql cnrt2 -c "select postgis_version()" 
# 3.4 USE_GEOS=1 USE_PROJ=1 USE_STATS=1

psql cnrt2 -c "select pgr_version()" 
# 3.6.1

qgis --version
# QGIS 3.38.0-Grenoble 'Grenoble' (37aa6188bc3)
```
