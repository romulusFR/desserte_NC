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

### Création des tables et chargement

Dans une base PostgreSQL supposée déjà créée et configurée, on exécute les scripts [01_download.sh](scripts/01_download.sh) puis [02_import_pg.sh](scripts/02_import_pg.sh) qui vont télécharger les données et les importer.
À l'issue de l'exécution, les tables suivantes sont créées dans la base PostgreSQL, voir le fichier [select_infos.sql](database/select_infos.sql) :

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

### Nettoyage

On exécute le script [alter_tables_pk_fk.sql](database/alter_tables_pk_fk.sql) pour durcir le schéma en ajoutant des clefs alternatives et desc lefs étrangères.
On corrige au passage quelques erreurs ponctuelles sur la version du 2024-07-16.

### Vérification

Les requêtes SQL suivantes permettent d'apprécier les volumes des tables.

#### Nombre total de kilomètres par type de segment

```sql
SELECT
  seg_type,
  COUNT(*) AS nb,
  ROUND(SUM(ST_Length(wkb_geometry))/1E3) AS long_km
FROM dittt_segments r
GROUP BY seg_type
ORDER BY long_km DESC;

--  seg_type |   nb   | long_km 
-- ----------+--------+---------
--  P        | 201529 |   30557
--  VCU      |  78516 |   10456
--  SP       |  39521 |    7772
--  VR       |    154 |      60
--  PC       |    185 |      43
--  G        |   2660 |      37
--  B        |    165 |      30
--  RP       |   1036 |      17
--  VS       |    106 |      16
--  VCS      |     10 |       4
--  PA       |    238 |       4
-- (11 rows)
```

#### Nombre de segments par IRIS

On regarde le nombre de segments et en particulier ceux de type _pistes_ (valeur `'P'`).
Les pistes sont marginales en zone urbaine, mais prépondérantes en brousse.

```sql
SELECT
  i.code_iris,
  i.lib_iris,
  ROUND(ST_area(i.wkb_geometry)/1E4) AS surface_ha,
  COUNT(n.objectid) AS nb_segments,
  COUNT(n.objectid) FILTER (WHERE seg_type = 'P')::numeric AS nb_pistes,
  ROUND(100 * COUNT(n.objectid) FILTER (WHERE seg_type = 'P')::numeric / COUNT(n.objectid), 2) AS pc_pistes,
  ROUND(1E6*COUNT(n.objectid) / ST_area(i.wkb_geometry))/100 AS segments_par_ha
FROM cnrt_iris i JOIN dittt_segments n ON ST_Contains(i.wkb_geometry, n.wkb_geometry)
WHERE 1=1
GROUP BY i.fid_iris
ORDER BY i.code_iris ASC;

--  code_iris |                     lib_iris                     | surface_ha | nb_segments | nb_pistes | pc_pistes | segments_par_ha 
-- -----------+--------------------------------------------------+------------+-------------+-----------+-----------+-----------------
--  0101      | Bélep                                            |       6433 |         926 |       428 |     46.22 |            0.14
--  0201      | Boulouparis village                              |      25791 |       11324 |      8777 |     77.51 |            0.44
--  0204      | Tomo-Ouinané                                     |      44073 |        7293 |      6398 |     87.73 |            0.17
--  0205      | Nassirah                                         |      16161 |        2823 |      2397 |     84.91 |            0.17
--  0301      | Bourail village                                  |       2074 |        1222 |       558 |     45.66 |            0.59
--  0302      | Poé Nessadiou                                    |      13329 |        3607 |      2268 |     62.88 |            0.27
--  0303      | Domaine Deva Le Cap                              |      28188 |        6943 |      4914 |     70.78 |            0.25
--  0304      | Nandaï Boghen                                    |      29652 |        5670 |      3461 |     61.04 |            0.19
--  0305      | Ny                                               |       6138 |        1368 |       481 |     35.16 |            0.22
--  0401      | Canala village                                   |       5192 |        1617 |       895 |     55.35 |            0.31
--  0403      | Gélima - Kuiné - Mia - Nakéty                    |       4622 |        1713 |      1150 |     67.13 |            0.37
--  0404      | Mé Kwaré                                         |      33393 |        5681 |      5236 |     92.17 |            0.17
--  0501      | Coeur de ville urbain                            |        172 |         455 |        29 |      6.37 |            2.65
--  0502      | Coeur de ville littoral                          |         77 |         160 |         0 |      0.00 |            2.08
--  0503      | Koutio Secal                                     |         79 |         268 |         0 |      0.00 |            3.38
--  0504      | Koutio érudits                                   |         86 |         207 |         4 |      1.93 |            2.41
--  0505      | Koutio Fortunes de mer                           |         77 |         124 |         2 |      1.61 |            1.62
--  0506      | Jacarandas I                                     |        188 |         127 |        13 |     10.24 |            0.68
```

## Calcul des trajets

### Préparation

On crée une vue _matérialisée_ `dittt_segments_pgr` qui structure les données sources des segments au format attendu par `pgRouting`.
On réduit les types de segments à seulement trois catégories sur les 11 initiales, voir le fichier [create_view_pgr_routing.sql](database/create_view_pgr_routing.sql) :

- les types `VCU`, `VCS`, `B`, `VR`, `A`, `RP` deviennent tous `R`, pour _route_,
- le type `P` reste `P`, pour _piste_,
- les autres types, à savoir `PC`, `G`, `PA` et `VS` deviennent `NR`, pour _non route_.

On obtient un extrait comme suit (en supprimant la colonne de géométrie).

```raw
   id   | source | target | seg_type | seg_sens | distance | deniv_m |   total_distance   | speed |         cost         |     reverse_cost     |
--------+--------+--------+----------+----------+----------+---------+--------------------+-------+----------------------+----------------------+
   2531 |  73944 |  73943 | P        | D        |       23 |       3 |  23.69993344399385 |    30 |   2.8439920132792618 |   2.8439920132792618 |
   2606 |   6735 |   6784 | X        | D        |      136 |       8 | 136.13126478598667 |     5 |     98.0145106459104 |     98.0145106459104 |
   4091 | 129601 | 129612 | P        | D        |       39 |       5 |  39.15517809531599 |    30 |    4.698621371437919 |    4.698621371437919 |
   4533 | 135180 | 135185 | P        | D        |      187 |      24 | 188.38362145470865 |    30 |   22.606034574565037 |   22.606034574565037 |
   5204 | 149120 | 149110 | P        | D        |       64 |       3 |  64.27757192808284 |    30 |     7.71330863136994 |     7.71330863136994 |
   5811 |  96911 |  96616 | P        | D        |     1730 |       0 |  1730.395672921742 |    30 |   207.64748075060902 |   207.64748075060902 |
   6764 |  21109 |  20965 | P        | D        |      135 |       5 | 135.40591987824868 |    30 |   16.248710385389842 |   16.248710385389842 |
   7260 | 129882 | 130074 | P        | D        |      312 |      63 | 317.91861289665326 |    30 |    38.15023354759839 |    38.15023354759839 |
   7385 |  20233 |  20343 | P        | D        |       55 |      12 | 55.963619531527975 |    30 |    6.715634343783356 |    6.715634343783356 |
   9526 |  93515 |  93530 | P        | D        |       43 |       5 | 43.378889913577204 |    30 |    5.205466789629265 |    5.205466789629265 |
   9714 |  21477 |  21507 | P        | D        |       34 |       4 |  34.40188332575905 |    30 |    4.128225999091086 |    4.128225999091086 |
   9996 | 144512 | 144510 | P        | D        |       43 |       4 |  43.21989353097915 |    30 |    5.186387223717498 |    5.186387223717498 |
  10352 |  24012 |  24133 | P        | D        |      215 |      11 |   214.862908473982 |    30 |    25.78354901687784 |    25.78354901687784 |
  10561 | 138397 | 138410 | P        | D        |       11 |       0 | 10.647242292350215 |    30 |   1.2776690750820259 |   1.2776690750820259 |
  11286 | 139527 | 181254 | P        | D        |       46 |       1 |  46.47503631207445 |    30 |    5.577004357448934 |    5.577004357448934 |
  12954 |  14303 |  14299 | X        | D        |      130 |      16 |  131.3424740308101 |     5 |    94.56658130218328 |    94.56658130218328 |
  13019 |  16139 |  16176 | X        | D        |      104 |       7 | 104.16797541725725 |     5 |    75.00094230042522 |    75.00094230042522 |
  13056 |  14239 |  14225 | X        | D        |       36 |       5 |  35.95506859052979 |     5 |    25.88764938518145 |    25.88764938518145 |
  14405 | 159194 | 159191 | X        | D        |       13 |       1 | 12.906964169454719 |    10 |    4.646507101003699 |    4.646507101003699 |
  14764 | 142325 | 142493 | P        | D        |      188 |       4 |  188.4099120648337 |    30 |   22.609189447780043 |   22.609189447780043 |
  14813 | 142209 | 142199 | P        | D        |       31 |       1 | 30.845765344883205 |    30 |   3.7014918413859843 |   3.7014918413859843 |
  15030 | 107221 | 107205 | P        | D        |      138 |       1 | 137.87326836809217 |    30 |    16.54479220417106 |    16.54479220417106 |
  15736 |  20850 |  20849 | P        | D        |        6 |       1 | 5.8264334933933055 |    30 |   0.6991720192071966 |   0.6991720192071966 |
  18970 | 102285 | 102247 | P        | D        |      209 |       0 | 208.83727668121665 |    30 |   25.060473201745996 |   25.060473201745996 |
  21557 | 101193 | 101253 | P        | D        |      205 |       0 | 204.80203474722632 |    30 |   24.576244169667156 |   24.576244169667156 |
  21960 | 151778 | 151757 | P        | D        |       62 |       6 |  62.01349654329259 |    30 |     7.44161958519511 |     7.44161958519511 |
  22036 |  92054 |  92049 | P        | D        |       19 |       0 | 19.046222723552408 |    30 |   2.2855467268262886 |   2.2855467268262886 |
  22157 |  99413 |  99438 | P        | D        |      114 |       6 | 114.61926430901472 |    30 |   13.754311717081766 |   13.754311717081766 |
  22306 | 114333 | 114402 | P        | D        |       81 |       1 |  80.65686423243504 |    30 |    9.678823707892205 |    9.678823707892205 |
  24250 |  99211 |  99226 | P        | D        |       27 |       2 | 27.383977314055187 |    30 |   3.2860772776866223 |   3.2860772776866223 |
  24486 | 107831 | 107849 | P        | D        |       51 |       1 | 51.332368928528915 |    30 |    6.159884271423469 |    6.159884271423469 |
  24864 |  95148 |  95234 | P        | D        |      456 |       4 | 456.37937388313446 |    30 |    54.76552486597613 |    54.76552486597613 |
  25482 | 182030 | 106560 | P        | D        |       90 |       2 |  90.48075354470839 |    30 |   10.857690425365007 |   10.857690425365007 |
  26170 |  92137 |  92105 | P        | D        |      416 |       4 |  415.8410390161917 |    30 |      49.900924681943 |      49.900924681943 |
  30875 | 118620 | 118636 | P        | D        |       54 |       1 | 54.066553923615785 |    30 |    6.487986470833894 |    6.487986470833894 |
  31029 | 114726 | 114838 | P        | D        |      103 |      15 | 104.45988882216065 |    30 |   12.535186658659278 |   12.535186658659278 |
  32787 | 112157 | 112106 | P        | D        |       87 |       4 |  87.29915600763657 |    30 |   10.475898720916387 |   10.475898720916387 |
  33690 |  10634 |  10649 | X        | D        |       99 |       8 |  99.80180708079313 |     5 |    71.85730109817105 |    71.85730109817105 |
  33726 |  15515 |  15549 | X        | D        |      228 |      23 |  229.4858358455314 |     5 |    165.2298018087826 |    165.2298018087826 |
  33935 |  92789 |  92770 | X        | D        |       65 |       6 |  65.71015364092206 |     5 |    47.31131062146388 |    47.31131062146388 |
  34437 | 116406 | 116379 | P        | D        |       41 |       1 |  40.96291915599641 |    30 |    4.915550298719569 |    4.915550298719569 |
  34750 | 122717 | 122770 | P        | D        |      147 |       6 | 147.12602131448963 |    30 |   17.655122557738753 |   17.655122557738753 |
  35223 | 155136 | 155036 | X        | D        |      258 |      15 |  258.8079289938666 |     5 |   186.34170887558395 |   186.34170887558395 |
  35390 | 122382 | 122248 | X        | D        |      185 |       3 |   185.287229334341 |     5 |   133.40680512072552 |   133.40680512072552 |
  35432 | 122863 | 122880 | X        | D        |       13 |       2 | 13.243684677016333 |     5 |     9.53545296745176 |     9.53545296745176 |
  35703 | 119206 | 119198 | X        | D        |       34 |       7 | 34.820536358987674 |     5 |   25.070786178471128 |   25.070786178471128 |
  38267 | 124631 | 124668 | X        | D        |      127 |      11 | 127.48839133693748 |     5 |    91.79164176259499 |    91.79164176259499 |
  38871 | 110822 | 110948 | X        | D        |      251 |      73 |  261.1214895403874 |     5 |   188.00747246907895 |   188.00747246907895 |
  39770 |  97326 |  97339 | X        | D        |       34 |       6 |  34.82088705117006 |     5 |   25.071038676842445 |   25.071038676842445 |
  40686 |  20545 |  20483 | P        | D        |       27 |       3 | 27.425341772953125 |    30 |   3.2910410127543748 |   3.2910410127543748 |
  41349 |  14925 |  14901 | P        | D        |       80 |       7 |  80.50623795270936 |    30 |    9.660748554325123 |    9.660748554325123 |
  42445 | 148181 | 148180 | P        | D        |      252 |      46 |  256.4726226080874 |    30 |   30.776714712970488 |   30.776714712970488 |
  43567 | 149105 | 149175 | X        | D        |      916 |      78 |  919.5395588067488 |     5 |    662.0684823408592 |    662.0684823408592 |
  44255 |  56370 |  56335 | P        | D        |       40 |       1 |  40.40096380427812 |    30 |    4.848115656513374 |    4.848115656513374 |
  44779 |  68352 |  68337 | P        | D        |       69 |       9 |  69.53868380966733 |    30 |     8.34464205716008 |     8.34464205716008 |
  46356 |  57656 |  57652 | R        | D        |       68 |       0 |  68.41720571164056 |    50 |     4.92603881123812 |     4.92603881123812 |
  47733 |  61516 |  61519 | P        | D        |        4 |       1 |  4.114404083570949 |    30 |   0.4937284900285138 |   0.4937284900285138 |
  49106 |  83162 |  83176 | P        | D        |       25 |       1 |  25.46674992446989 |    30 |   3.0560099909363867 |   3.0560099909363867 |
  49241 |  87054 |  87047 | X        | D        |        6 |       0 |  6.475425740337137 |     5 |    4.662306533042739 |    4.662306533042739 |
```

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
