# Élaboration d'une matrice de desserte en Nouvelle-Calédonie

- [Élaboration d'une matrice de desserte en Nouvelle-Calédonie](#élaboration-dune-matrice-de-desserte-en-nouvelle-calédonie)
  - [Import des données](#import-des-données)
    - [Création des tables et chargement](#création-des-tables-et-chargement)
    - [Nettoyage](#nettoyage)
    - [Vérification](#vérification)
  - [Préparation du calcul des trajets avec `pgRouting`](#préparation-du-calcul-des-trajets-avec-pgrouting)
    - [Vue des segments au format `pgRouting`](#vue-des-segments-au-format-pgrouting)
    - [Composantes connexes et résolution des nœuds DITTT](#composantes-connexes-et-résolution-des-nœuds-dittt)
    - [Desserte depuis les POI](#desserte-depuis-les-poi)
  - [Calcul et agrégation des coûts de desserte](#calcul-et-agrégation-des-coûts-de-desserte)
    - [Table des dessertes détaillées](#table-des-dessertes-détaillées)
    - [Agrégation par IRIS](#agrégation-par-iris)
    - [Export des résultats](#export-des-résultats)
  - [Annexe](#annexe)
    - [Environnement utilisé](#environnement-utilisé)
    - [Liste et taille des tables](#liste-et-taille-des-tables)
    - [Structures finales de l'ensemble des tables](#structures-finales-de-lensemble-des-tables)

Ce document décrit la méthode calcul du temps de trajet par la route entre les IRIS et des points d'intérêts (POI), notamment les sites miniers (centre et usines) ou les établissements de santé de Nouvelle-Calédonie.

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

Les schémas finaux après exécution de toutes les étapes sont donnés en annexe.

### Nettoyage

On exécute le script [alter_tables_pk_fk.sql](database/alter_tables_pk_fk.sql) pour durcir le schéma en ajoutant des clefs alternatives et des clefs étrangères.
On corrige au passage quelques erreurs ponctuelles sur la version du 2024-07-16.
Voir le fichier [03_cleaning.sh](scripts/03_cleaning.sh) qui exécute les fichiers SQL adéquats.

### Vérification

Les requêtes SQL suivantes permettent d'apprécier la qualité et le volume des données.

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
--  0601      | Farino                                           |       4807 |        1232 |       547 |     44.40 |            0.26

```

#### La longueur de la R.T.1 : 402 km

```sql
SELECT sum(st_length(wkb_geometry))/1e3 AS long_km
FROM dittt_segments JOIN dittt_denominations on seg_nom_gu = nom_guid
WHERE nom_code = 'R.T.1';

--       long_km      
-- -------------------
--  401.6447358156211
```

## Préparation du calcul des trajets avec `pgRouting`

Le fichier [04_prepare_pgr.sh](scripts/04_prepare_pgr.sh) exécute les programmes SQL des trois sous-sections.

### Vue des segments au format `pgRouting`

On crée une vue _matérialisée_ `dittt_segments_pgr` qui structure les données sources au [format attendu par `pgRouting`](https://docs.pgrouting.org/3.6/en/pgr_dijkstraNearCost.html#edges-sql).
On prend en compte la direction des segments, la pente et la vitesse maximale autorisée dans le calcul des coûts.
De plus, on réduit les types à trois sur les 11 initiaux, voir le fichier [create_view_pgr.sql](database/create_view_pgr.sql) :

- Les types `VCU`, `VCS`, `B`, `VR`, `A`, `RP` deviennent tous `R`, pour _route_,
- Le type `P` reste `P`, pour _piste_,
- Les autres types, à savoir `PC`, `G`, `PA` et `VS` deviennent `NR`, pour _non route_.

On obtient un extrait comme suit avec la requête `select * from dittt_segments_pgr tablesample bernoulli(.005);`.

```raw
   id   | source | target | seg_type | seg_sens | distance | deniv_m |   total_distance   | speed |        cost        |    reverse_cost    
--------+--------+--------+----------+----------+----------+---------+--------------------+-------+--------------------+--------------------
   3736 | 132158 | 132155 | P        | D        |       57 |       1 |  57.47487104456262 |    30 |  6.896984525347514 |  6.896984525347514
 203290 | 180277 | 199113 | R        | D        |       69 |       3 |  68.88898975360519 |    50 |  4.960007262259573 |  4.960007262259573
 206516 | 185873 | 195805 | R        | D        |       23 |       0 |  23.44438010752035 |    50 |  1.687995367741465 |  1.687995367741465
  18005 |  94222 |  94204 | X        | D        |       79 |       1 |  78.51453385221917 |     5 |  56.53046437359781 |  56.53046437359781
  48567 |  87733 |  87772 | P        | D        |       26 |       0 |  26.38008924283453 |    30 |  3.165610709140143 |  3.165610709140143
  83870 |  73094 |  73060 | X        | D        |      173 |      19 |  174.2559863110222 |     5 |   125.464310143936 |   125.464310143936
  90846 |  62556 |  62624 | P        | D        |       86 |       6 |   86.0641647575717 |    30 | 10.327699770908604 | 10.327699770908604
 119974 | 190934 | 111107 | P        | D        |       97 |       1 |  96.73794243361631 |    30 | 11.608553092033956 | 11.608553092033956
 198439 | 198148 | 197399 | P        | D        |       69 |       0 |  69.17732474378623 |    30 |  8.301278969254348 |  8.301278969254348
 241111 | 208483 | 208970 | P        | D        |      122 |       0 | 122.29569950215429 |    30 | 14.675483940258514 | 14.675483940258514
 252103 | 225378 | 225379 | P        | D        |      280 |       5 | 279.82897145348653 |    30 |  33.57947657441838 |  33.57947657441838
 297747 | 259902 | 258090 | P        | D        |      295 |      23 | 296.24233359406423 |    30 |  35.54908003128771 |  35.54908003128771
(12 rows)
```

#### Trajets de référence

On calcule un trajet de référence entre les deux sites de l'UNC et l'usine du nord :

- Nœud _UNC - site Nouville_ : `objectid = 270424` (type `J`).
  - Point situé au 102 Av. James Cook à Nouville, à l'intersection avec la rue Kataoui.
  - GPS : -22.2619,166.4042
- Nœud _UNC - site Baco_ : `objectid = 200545` (type `FDR`).
  - Point situé au bout du chemin entre l'UNC et la caserne de pompiers, au début de la RPN2 / Koné Tiwaka.
  - GPS : -21.0923,164.8913
- Nœud _usine du nord_ : `objectid = 91270` (type `J`).
  - Point situé au plus proche de celui de l'usine dans les données DIMENC, sur la piste après la RT1, au pied du four.
  - GPS : -21.0138,164.6836

On donne la requête, un extrait du résultat et une visualisation graphique du trajet ci-après.

```sql
SELECT
  direction.edge,
  e.seg_type,
  e.distance,
  e.speed,
  greatest(e.cost, e.reverse_cost) as cost,
  ROUND(direction.agg_cost) AS agg_cost
FROM pgr_dijkstra('SELECT * FROM dittt_segments_pgr',
                   270424, 200545, TRUE) AS direction
     JOIN dittt_segments_pgr e ON direction.edge = e.id
ORDER BY seq;

--   edge  | seg_type | distance | speed |         cost         | agg_cost 
-- --------+----------+----------+-------+----------------------+----------
--  307443 | R        |       35 |    50 |    2.503083667560222 |        0
--  302188 | R        |      114 |    50 |    8.217825165963008 |        3
--  302249 | R        |       32 |    50 |   2.2773306928972183 |       11
--  306453 | R        |       15 |    50 |    1.066954653737687 |       13
-- ...
--  217857 | R        |       98 |    50 |    7.036030838506505 |    10496
--  217854 | R        |       54 |    50 |   3.9159900551178333 |    10503
--  227627 | P        |       12 |    30 |   1.4302731087691083 |    10507
--  217453 | P        |       88 |    30 |   10.572007930984094 |    10508
-- (1185 rows)
```

![Trajet de référénce de Nouville à Baco](img/trajet-reference-Nouville-Baco.png)

Les coûts sont en secondes, ici 10 518 au total soit 02:55:18 pour une longueur totale de 263 305 mètres en parcourant 1 185 segments.
C'est un trajet particulièrement détaillé, dû à la finesse du réseau DITTT.
On compare le même trajet par les services qui indique tous la même distance et des durées légèrement supérieures :

- [Google Maps](https://maps.app.goo.gl/VbibXFzr3HYfEEHw7) : durée de 03:13:00, soit un écart de 10%.
- [OpenStreetMap avec l'algorithme GraphHopper](https://www.openstreetmap.org/directions?engine=graphhopper_car&route=-22.2619%2C166.4042%3B-21.0929%2C164.8917#map=10/-21.6822/165.6728) : durée de 02:58:00, soit un écart de 2%.
- [OpenStreetMap avec l'algorithme OSRM](https://www.openstreetmap.org/directions?engine=fossgis_osrm_car&route=-22.2619%2C166.4042%3B-21.0929%2C164.8917) ou via [l'API directement](http://router.project-osrm.org/route/v1/driving/166.4042,-22.2619;164.8913,-21.0923) : distance de 263 809 mètres et une durée un peu plus pessimiste de 03:32:12.

On teste sur le même trajet les fonctions de plus court chemin qu'on utilisera dans la suite.

```sql
-- trajet simple, correspont à la somme agg_cost + cost du trajet avec pgr_dijkstra
SELECT * FROM pgr_dijkstraCost('SELECT * FROM dittt_segments_pgr', 270424, 200545, TRUE) AS direction;
--  start_vid | end_vid |      agg_cost      
-- -----------+---------+--------------------
--     270424 |  200545 | 10518.802913674612
-- Time: 980,637 ms

-- écarts de 3 secondes entre les deux directions via cost matrix
SELECT * FROM pgr_dijkstraCostMatrix('SELECT * FROM dittt_segments_pgr', ARRAY[270424, 200545], TRUE) AS direction;

--  start_vid | end_vid |      agg_cost      
-- -----------+---------+--------------------
--     200545 |  270424 | 10515.429965522622
--     270424 |  200545 | 10518.802913674612
-- Time: 1050,469 ms (00:01,050)

-- de l'usine du nord aux deux sites UNC
SELECT * FROM pgr_dijkstraCost('SELECT * FROM dittt_segments_pgr', 91270, ARRAY[270424, 200545], TRUE) AS direction;
--  start_vid | end_vid |      agg_cost      
-- -----------+---------+--------------------
--      91270 |  200545 | 1348.1856932073051
--      91270 |  270424 | 11798.774051661303
-- Time: 989,532 ms
```

### Composantes connexes et résolution des nœuds DITTT

Une première étape du calcul est de calculer pour chaque POI identifié géométriquement un nœud DITTT le plus proche.
Ce problème est appelé [_map matching_](https://en.wikipedia.org/wiki/Map_matching).
Pour cela, on ajoute une colonne `dittt_noeud_ref` à chacune des tables des POI avec une clef étrangère vers la table DITTT.

On ajoute préalablement un identifiant de composante connexe du réseau à chaque nœud, cela permettra de vérifier que les nœuds DITTT identifiés sont bien accessibles par la route, c'est-à-dire dans un morceau connexe du réseau principal.

```sql
select component, count(*) as count from dittt_noeuds group by component order by count desc;

--  component | count  
-- -----------+--------
--          1 | 185273
--       NULL |  36662
--      90958 |  10205
--      81484 |   7490
--     171983 |   3875
--      77981 |   1105
--      17148 |    831
--      11699 |    528
--      63584 |    449
--      80307 |    416
--     150877 |    397


--     254791 |      1
--     255270 |      1
--     283939 |      1
--      60631 |      1
-- (5155 rows)
```

Les meilleurs voisins sont calculés comme suit, ce qui sert à remplir l'attribut `ditt_noeud_ref` ajouté aux tables des POI.

```sql
-- les plus grande composantes connexes, classées par tailles relatives
with large_cc as(
  select
    component,
    count(*) as size_cc,
    100*count(*)::numeric / (select count(*) from dittt_noeuds where component is not null) as size_pc
  from dittt_noeuds
  where component is not null
  group by component
  order by size_cc desc
),

-- calcul du noeud DITTT le plus proche du POI
-- voir https://www.postgis.net/workshops/postgis-intro/knn.html pour le calcul
best_neighbour as(
  select closest.objectid as dittt_noeud_ref, closest.component as cc, poi.objectid as poi_id
  from dimenc_centres poi join lateral
      (select *
        from dittt_noeuds n join large_cc using (component)
        --- la sélection aux cc qui concernent au moins 1/10000 des p+r produit 17 composantes
        where size_pc >= 0.01
        order by poi.wkb_geometry <-> n.wkb_geometry
        fetch first 1 row only
      ) closest on true
)

select * from best_neighbour;

--  dittt_noeud_ref |  cc   | poi_id 
-- -----------------+-------+--------
--            97042 |     1 |      1
--           222865 |     1 |      2
--            37912 |     1 |      3
--            67633 |     1 |      4
--            96789 |     1 |      5
--           105239 |     1 |      6
--           104243 |     1 |      7
--           242556 |     1 |      8
--            52227 |     1 |      9
--            16221 |     1 |     10
--           156743 |     1 |     11
--           113373 |     1 |     12
--           105975 |     1 |     13
--            98949 |     1 |     14
--            97478 |     1 |     15
--            19791 |     1 |     16
--            35694 |     1 |     17
--            49291 |     1 |     18
--            42759 |     1 |     19
--            34980 |     1 |     20
--           240175 |     1 |     21
--           241745 |     1 |     22
--           227242 |     1 |     23
--           223488 |     1 |     24
--           250645 |     1 |     25
--           239169 |     1 |     26
--            64463 |     1 |     27
--            65165 |     1 |     28
--            66036 |     1 |     29
--           104458 |     1 |     30
--           104020 |     1 |     31
--            76627 | 75918 |     32
--           219365 |     1 |     33
--            37101 |     1 |     34
--           236857 |     1 |     35
--            42160 |     1 |     36
--           256461 |     1 |     37
--           139956 |     1 |     38
--           240513 |     1 |     39
--            34186 |     1 |     40
-- (40 rows)
```

On remarque que toutes les mines sauf une seule sont dans la composante connexe numéro 1, c'est-à-dire la principale qui contient Nouméa.
Il s'agit de la mine de Ouinné de la _Société minière Georges Montagnat_ qui est située sur la Côte Oubliée et n'est accessible **que** par la mer.

Pour les POI de type établissements de santé, contrairement aux sites miniers, ceux-ci ne sont pas tous situés sur la grande terre.
Les composantes connexes avec le nombre d'établissements concernés sont les suivantes, qui correspondent aux îles de l'archipel. Ci-dessous [le résultat de la requête](database/select_best_neighbour_component_sante.sql) commenté :

```raw
 component | count 
-----------+-------
         1 |  1296 // Grande-Terre
     77981 |     3 // Ile des pins
     81484 |     6 // Maré
     90958 |    23 // Lifou
    160125 |     1 // Bélep
    171983 |     4 // Ouvéa
(6 rows)
```

On vérifie enfin que chaque `dittt_noeud_ref` ne correspond bien qu'à un seul POI dans chacune des tables.
C'est vrai pour les sites miniers, mais **pas** pour les établissements de santés, où par exemple plusieurs praticiens peuvent exercer au même endroit.
Il faut donc être vigilant sur les jointures avec `dittt_noeud_ref`.

```sql
select count(distinct objectid) from dimenc_usines poi where wkb_geometry is not null;
select count(distinct dittt_noeud_ref) from dimenc_usines poi where wkb_geometry is not null;
-- 3 et 3 : OK

select count(distinct objectid) from dimenc_centres poi where wkb_geometry is not null;
select count(distinct dittt_noeud_ref) from dimenc_centres poi where wkb_geometry is not null;
-- 40 et 40 : OK

select count(distinct fid_etab) from dass_etabs_sante poi where wkb_geometry is not null;
select count(distinct dittt_noeud_ref) from dass_etabs_sante poi where wkb_geometry is not null;
-- 1333 et 763 : KO /!\
```

#### Distances entre POI et nœuds DITTT

On vérifie que les distances entre les coordonnées d'origines des POI et les nœuds de référence sont raisonnables.

```sql
SELECT poi.site, ROUND(poi.wkb_geometry <-> n.wkb_geometry) AS distance_m
FROM dimenc_usines poi JOIN dittt_noeuds n ON poi.dittt_noeud_ref = n.objectid
ORDER BY distance_m DESC;

SELECT poi.site_minie, ROUND(poi.wkb_geometry <-> n.wkb_geometry) AS distance_m
FROM dimenc_centres poi JOIN dittt_noeuds n ON poi.dittt_noeud_ref = n.objectid
ORDER BY distance_m DESC;

SELECT poi.denominatio, ROUND(poi.wkb_geometry <-> n.wkb_geometry) AS distance_m
FROM dass_etabs_sante poi JOIN dittt_noeuds n ON poi.dittt_noeud_ref = n.objectid
ORDER BY distance_m DESC;

--    site   | distance_m 
-- ----------+------------
--  Goro     |        208
--  Doniambo |        136
--  Koniambo |         76

--           site_minie          | distance_m 
-- ------------------------------+------------
--  KOUE                         |        238
--  VERSE RACHEL                 |        138
--  THIO PLATEAU                 |        121
--  KADJITRA                     |        105
--  KOPETO                       |        100
--  MICHEL 38                    |         96
--  ALICE-PHILIPPE               |         77
--  TIEBAGHI                     |         69
--  KOUAOUA MEA-KIEL-DOUMA       |         63
--  PORO BONINI                  |         63
--  OUACO TAOM                   |         63
--  BOGOTA SUIVANTE-BIENVENUE    |         55
--  GRAZIELLA                    |         54
--  PINPIN 1B                    |         54
--  DOTHIO                       |         53
--  BOUALOUDJELIMA               |         50
--  OUACO OUAZANGOU              |         50
--  BOGOTA EARLY DOWN-NIGL       |         43
--  PORO FRANCAISE               |         40
--  THIO CAMP DES SAPINS         |         40
--  CAP BOCAGE                   |         38
--  PB2 carrière basse           |         37
--  NAKETY EDOUARD-EUREKA-CIRCEE |         37
--  OUINNE                       |         37
--  MICHEL 37                    |         35
--  PINPIN 1A                    |         35
--  OPOUE                        |         33
--  NAKETY PLATEAU               |         33
--  GORO                         |         31
--  CLAUDE ET PHILOMENE          |         30
--  STAMBOUL                     |         29
--  NAKETY LUCIENNE              |         28
--  POUM                         |         28
--  KONIAMBO                     |         25
--  TUNNEY                       |         19
--  TOMO-SMMO 43                 |         18
--  ADA                          |         16
--  ETOILE DU NORD               |         14
--  VULCAIN                      |         12
--  OUALA CARRIERE C             |         11
```

### Desserte depuis les POI

On va utiliser [la famille des fonctions de calcul de plus courts chemins basées sur l'algorithme de Dijkstra](https://docs.pgrouting.org/3.6/en/dijkstra-family.html) pour le calcul de desserte, lesquelles sont [issue de la Boost Graph Library](https://www.boost.org/doc/libs/1_85_0/libs/graph/doc/dijkstra_shortest_paths.html).

On calcule le temps de trajet _de chaque POI **vers** les nœuds DITTT_ (et non pas _des nœuds un à un vers les POI_) avec [pgr_dijkstraCost](https://docs.pgrouting.org/3.6/en/pgr_dijkstraCost.html) car sa complexité [est proportionnelle au nombre de sources](https://docs.pgrouting.org/3.6/en/pgr_dijkstraCost.html), mais en revanche [la complexité n'est pas meilleure avec une seule destination qu'avec plusieurs](https://www.boost.org/doc/libs/1_85_0/libs/graph/doc/graph_theory_review.html#sec:shortest-paths-algorithms).

#### Exemple entre l'usine du nord et les nœuds de Farino

La requête suivante liste tous les couples _(source, destination)_ depuis le POI 9127 (l'usine du nord) vers les nœuds _carrossables_ de l'IRIS de Farino. _Carrossable_ signifiant qu'il y a au moins un segment de route relié à ce nœud de type `VCU`, `VCS`, `B`, `VR`, `A`, `RP` (hors nœuds de type piste `P`).

```sql
with carrossable as (
  select distinct source
  from dittt_segments_pgr
  where seg_type = 'R'
  
  union
  
  select distinct target
  from dittt_segments_pgr
  where seg_type = 'R'
)

select 
  91270::integer as "source",
  objectid::integer as "target"
from dittt_noeuds n join cnrt_iris i on st_contains(i.wkb_geometry, n.wkb_geometry)
where lib_iris = 'Farino' and n.objectid in (select * from carrossable);

-- 664, Farino comptant 44.4% de segments de route de type piste
```

On peut utiliser cette requête pour calculer toutes les durées de trajet de l'usine du nord vers les nœuds de Farino, on obtient ainsi des durées de travers entre 113.5 et 133.9 minutes, avec une moyenne de 120 minutes, ce qui paraît cohérent, compte tenu du léger optimisme des durées de trajets vérifiées précédemment.
Voir [le fichier SQL](database/select_trajet_nord_vers_farino.sql).
Notons qu'on utilise les [chaînes de caractères SQL sur plusieurs lignes](https://www.postgresql.org/docs/current/sql-syntax-lexical.html#SQL-SYNTAX-STRINGS).

```sql
SELECT *
FROM pgr_dijkstraCost(
    'select * from dittt_segments_pgr',
    'with carrossable as ( '
    'select distinct source '
    'from dittt_segments_pgr '
    'where seg_type = ''R'' '
    'union '
    'select distinct target '
    'from dittt_segments_pgr '
    'where seg_type = ''R'' '
    ') '
    'select '
    '  91270::integer as "source", '
    '  objectid::integer as "target" '
    'from dittt_noeuds n join cnrt_iris i on st_contains(i.wkb_geometry, n.wkb_geometry) '
    'where lib_iris = ''Farino'' and n.objectid in (select * from carrossable);',
    TRUE) AS direction;
```

## Calcul et agrégation des coûts de desserte

Le script [05_compute.sh](scripts/05_compute.sh) exécute les fichiers SQL de calcul de cette section.

### Table des dessertes détaillées

On exécute le fichier [create_table_desserte.sql](database/create_table_desserte.sql) pour créer une table `desserte_poi` des résultats intermédiaires comme suit, où on utilise le nom de la table des POI comme valeur de `poi_type`.
Le script crée aussi une table pour les agrégats qu'on détaillera plus bas.

```raw
             Table "public.desserte_poi"
  Column  |  Type   | Collation | Nullable | Default 
----------+---------+-----------+----------+---------
 source   | integer |           | not null | 
 poi_type | text    |           | not null | 
 poi_id   | integer |           | not null | 
 target   | integer |           | not null | 
 cost     | numeric |           |          | 
Indexes:
    "desserte_poi_pkey" PRIMARY KEY, btree (poi_type, poi_id, target)
Check constraints:
    "desserte_poi_poi_type_check" CHECK (poi_type = ANY (ARRAY['dimenc_usines'::text, 'dimenc_centres'::text, 'dass_etabs_sante'::text]))
Foreign-key constraints:
    "desserte_poi_source_fkey" FOREIGN KEY (source) REFERENCES dittt_noeuds(objectid)
    "desserte_poi_target_fkey" FOREIGN KEY (target) REFERENCES dittt_noeuds(objectid)
```

On ne va considérer que les destinations qui sont des extrémités de segments de route.

```sql
WITH routes AS (
  SELECT DISTINCT source FROM dittt_segments_pgr WHERE seg_type = 'R'
  UNION
  SELECT DISTINCT target FROM dittt_segments_pgr WHERE seg_type = 'R'
)
SELECT count(*) FROM dimenc_usines poi CROSS JOIN routes;
--  75209 dont 61130 dans la composante 1 
```

On reprend la requête de la [section précédente](#desserte-depuis-les-poi) pour matérialiser le résultat dans `desserte_poi`.
On prend soin d'ouvrir les jointures pour bien avoir tous les couples avec un coût `NULL` qui représente les valeurs infinies, quand il n'y a pas de trajet.
Par exemple, les trajets des usines vers les nœuds dans les IRIS des îles (Loyautés, Bélep ou des Pins) doivent être tous infinis.

```sql
WITH dans_iles AS(
  SELECT n.objectid
  FROM dittt_noeuds n JOIN cnrt_iris i ON st_contains(i.wkb_geometry, n.wkb_geometry)
  WHERE i.nom_com IN ('BELEP', 'ILE DES PINS', 'LIFOU', 'MARE', 'OUVEA')
)

SELECT *
FROM desserte_poi
WHERE target IN (SELECT * FROM dans_iles) AND cost IS NOT NULL AND poi_type IN ('dimenc_usines', 'dimenc_centres');
-- (0 rows)
```

#### Traitement en masses de POI

Si le nombre de POI est trop important, `pgRouting` peut avoir des difficultés à allouer la RAM et faillir avec l'erreur `ERROR:  XX000: invalid memory alloc request size ...`.
Il faut alors décomposer la requête avec un **plus petit nombre de sources** dans `pgr_dijkstraCost` en insérant les résultats partiels à `desserte_poi`.

```sql
-- regroupés par IRIS
select nom_com, type_etabli, count(*) as nb
from dass_etabs_sante e right outer join cnrt_iris i on st_contains(i.wkb_geometry,e.wkb_geometry)
group by nom_com, type_etabli
order by nom_com, type_etabli, nb desc;

select type_etabli, count(*) as nb
from dass_etabs_sante
group by type_etabli
order by nb desc;

--              type_etabli              | nb  
-- --------------------------------------+-----
--  Infirmiers                           | 226
--  Cabinet médical                      | 179
--  Kinésithérapie                       | 136
--  Orthophonie                          | 110
--  Cabinet dentaire                     | 104
--  Pharmacie                            |  73
--  Ostéopathie                          |  63
--  Ambulance                            |  62
--  Opticiens                            |  42
--  Dispensaire                          |  34
--  Sage-Femme                           |  34
--  Matériel médical                     |  22
--  Laboratoire                          |  19
--  Etab personnes agées                 |  19
--  Psychiatrie                          |  19
--  Podologie                            |  18
--  Collect. Terr. et Etat               |  14
--  Etab personnes handicapées           |  14
--  Gynécologie                          |  12
--  Ophtalmologie                        |  11
--  Cardiologie                          |  10
--  Imagerie médicale                    |  10
--  Hôpitaux                             |   9
--  Audioprothésiste                     |   9
--  Orthoptie                            |   8
--  Cabinet de Diététique/Nutritionniste |   8
--  Dermatologie                         |   8
--  Chirurgie                            |   8
--  Dialyse                              |   6
--  Oxygène médical                      |   6
--  Pédiatrie                            |   5
--  Entreprises autres                   |   5
--  Cabinet ORL                          |   5
--  Centre médico-psychologique (CMP)    |   4
--  Neurologie                           |   4
--  Pneumologie                          |   4
--  Cabinet chiropractique               |   3
--  Endocrinologie                       |   3
--  Orthodontie                          |   3
--  Angiologie                           |   3
--  Urologie                             |   3
--  Gastro-Entérologie                   |   2
--  Anesthésie                           |   2
--  Médecine du travail                  |   2
--  Ø                                    |   2
--  Autres                               |   1
--  Allergologie                         |   1
--  Néphrologie                          |   1
--  Stomatologie                         |   1
--  Protection de l'enfance              |   1
--  Gériatrie                            |   1
--  Grossiste Pharmacie                  |   1
--  Rhumatologie                         |   1
-- (53 rows)
```

Ici, on se limite à la sélection `poi.type_etabli IN ('Dispensaire', 'Hôpitaux', 'Pharmacie', 'Sage-Femme')`.

### Agrégation par IRIS

À ce stade, on dispose des données comme suit :

```sql
select * from desserte_poi  tablesample bernoulli(0.0001);

--  source |     poi_type     | poi_id | target |       cost       
-- --------+------------------+--------+--------+------------------
--  255591 | dimenc_usines    |      2 |  45902 | 13630.6480324089
--  255591 | dimenc_usines    |      2 | 208413 | 9186.45815349257
--   16221 | dimenc_centres   |     10 | 266726 | 10162.8992229618
--  240513 | dimenc_centres   |     39 |   6129 | 6057.68715568927
--  250645 | dimenc_centres   |     25 |  60992 | 4725.77615258666
--   62373 | dass_etabs_sante |     56 | 221287 | 4108.01902108972
--   67073 | dass_etabs_sante |    893 | 135230 |  12524.410304495
--   68769 | dass_etabs_sante |   1319 | 248178 |  7502.6703178984
--  102196 | dass_etabs_sante |    497 | 273203 | 13505.7066416541
--  130905 | dass_etabs_sante |    491 |   8554 | 4402.86088536708
--  183892 | dass_etabs_sante |    876 | 127981 | 4486.75010213858
--  201237 | dass_etabs_sante |   1344 | 189270 | 6144.08622839343
--  261994 | dass_etabs_sante |    428 | 207591 | 4548.99162270812
--  268066 | dass_etabs_sante |    702 | 137832 | 12327.7803503244
--  274068 | dass_etabs_sante |   1148 |  40154 | 8949.51372466605
--  275933 | dass_etabs_sante |    217 | 218002 | 2203.91839249472


select poi_type, poi_id, count(*)
from desserte_poi
group by poi_type, poi_id
order by poi_type desc, poi_id;

--     poi_type     | poi_id | count 
-- ------------------+--------+-------
--  dimenc_usines    |      1 | 64060
--  dimenc_usines    |      2 | 64061
--  dimenc_usines    |      3 | 64060
--  dimenc_centres   |      1 | 64060
--  dimenc_centres   |      2 | 64060
--  dimenc_centres   |      3 | 64061
--  dimenc_centres   |      4 | 64060
--  dimenc_centres   |      5 | 64061
--  dimenc_centres   |      6 | 64060
--  dimenc_centres   |      7 | 64061
--  dimenc_centres   |      8 | 64061
--  dimenc_centres   |      9 | 64061
--  dimenc_centres   |     10 | 64061
--  dimenc_centres   |     11 | 64060
--  dimenc_centres   |     12 | 64061
--  dimenc_centres   |     13 | 64060
--  dimenc_centres   |     14 | 64060
--  dimenc_centres   |     15 | 64061
--  dimenc_centres   |     16 | 64061
--  dimenc_centres   |     17 | 64061
--  dimenc_centres   |     18 | 64061
--  dimenc_centres   |     19 | 64061
--  dimenc_centres   |     20 | 64061
--  dimenc_centres   |     21 | 64061
--  dimenc_centres   |     22 | 64061
--  dimenc_centres   |     23 | 64061
--  dimenc_centres   |     24 | 64061
--  dimenc_centres   |     25 | 64061
--  dimenc_centres   |     26 | 64061
--  dimenc_centres   |     27 | 64060
--  dimenc_centres   |     28 | 64061
--  dimenc_centres   |     29 | 64061
--  dimenc_centres   |     30 | 64061
--  dimenc_centres   |     31 | 64060
--  dimenc_centres   |     32 |    32
--  dimenc_centres   |     33 | 64061
--  dimenc_centres   |     34 | 64061
--  dimenc_centres   |     35 | 64061
--  dimenc_centres   |     36 | 64060
--  dimenc_centres   |     37 | 64061
--  dimenc_centres   |     38 | 64061
--  dimenc_centres   |     39 | 64061
--  dimenc_centres   |     40 | 64061
--  dass_etabs_sante |      7 | 64060
--  dass_etabs_sante |      8 | 64060
--  dass_etabs_sante |      9 |  1555
--  dass_etabs_sante |     10 | 64060
--  dass_etabs_sante |     14 | 64060
--  dass_etabs_sante |     15 | 64060
--  dass_etabs_sante |     16 |  1555
--  dass_etabs_sante |     17 | 64061
--  dass_etabs_sante |     18 | 64060
--  dass_etabs_sante |     19 |    53
--  dass_etabs_sante |     23 | 64060
--  dass_etabs_sante |     27 | 64060
--  dass_etabs_sante |     39 |  3560
--  dass_etabs_sante |     41 | 64061
--  dass_etabs_sante |     49 |  4373
--  dass_etabs_sante |     50 |  4373
--  dass_etabs_sante |     55 | 64060
-- ...
```

Pour calculer les matrices de dessertes des POI, il faut agréger les destinations de la table `desserte_poi` par _unité géographique_ comme les IRIS ou les communes.
La table `desserte_aggregate_iris` reprend les identifiants des POI de `desserte_poi` mais remplace les nœuds DITTT de destination par des IRIS pris dans `cnrt_iris`.

```raw
         Table "public.desserte_aggregate_iris"
    Column    |  Type   | Collation | Nullable | Default 
--------------+---------+-----------+----------+---------
 poi_type     | text    |           | not null | 
 poi_id       | integer |           | not null | 
 poi_name     | text    |           | not null | 
 iris_code    | text    |           | not null | 
 iris_libelle | text    |           |          | 
 minimum      | numeric |           |          | 
 mediane      | numeric |           |          | 
 moyenne      | numeric |           |          | 
 maximum      | numeric |           |          | 
Indexes:
    "desserte_aggregate_iris_pkey" PRIMARY KEY, btree (poi_type, poi_id, iris_code)
Check constraints:
    "desserte_aggregate_iris_poi_type_check" CHECK (poi_type = ANY (ARRAY['dimenc_usines'::text, 'dimenc_centres'::text, 'dass_etabs_sante'::text]))
Foreign-key constraints:
    "desserte_aggregate_iris_iris_code_fkey" FOREIGN KEY (iris_code) REFERENCES cnrt_iris(code_iris)
    "desserte_aggregate_iris_iris_libelle_fkey" FOREIGN KEY (iris_libelle) REFERENCES cnrt_iris(lib_iris)
```

Les requêtes de calcul des agrégats sont dans les fichiers suivants, où on considère **toutes** les combinaisons de POI et d'IRIS, même si l'IRIS n'est pas accessible (par exemple, une île depuis une usine) auquel cas la valeur est `NULL` :

- [Pour les usines](database/insert_table_desserte_aggregate_dimenc_usines.sql), 170 * 3 = 210 lignes, durée d'exécution d'environ 00:00:05.
- [Pour les centres](database/insert_table_desserte_aggregate_dimenc_centres.sql), 170 * 40 = 6800 lignes, durée d'exécution d'environ 00:01:03.
- [Pour les établissements de santé](database/insert_table_desserte_aggregate_dass_etabs_sante.sql), 170 * 149 = 25330 lignes, durée d'exécution d'environ 00:04:08.

### Export des résultats

On exporte les données dans un format appelé _normalisé_ en bases de données ou _tidy_ dans la communauté R (voir [tidyr.tidyverse.org](https://tidyr.tidyverse.org/articles/tidy-data.html)) qui est le plus agréable à utiliser programmatiquement.
On sépare les POI miniers des POI de santé.

```sql
\COPY (SELECT * FROM desserte_aggregate_iris WHERE poi_type IN ('dimenc_usines', 'dimenc_centres')) TO '../dist/desserte_mine_iris.csv' WITH (FORMAT CSV, DELIMITER ',', HEADER ON, NULL 'NULL');

\COPY (SELECT * FROM desserte_aggregate_iris WHERE poi_type IN ('dass_etabs_sante')) TO '../dist/desserte_etabs_sante_iris.csv' WITH (FORMAT CSV, DELIMITER ',', HEADER ON, NULL 'NULL');
```

Avec le script [pivot.py](scripts/pivot.py) on calcule une version pivotée en largeur pour un usage humain.

## Annexe

### Environnement utilisé

```bash
neofetch  --stdout
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

### Liste et taille des tables

```sql
SELECT pg_size_pretty(pg_database_size('cnrt2'));
--  pg_size_pretty 
-- ----------------
--  5375 MB
```

```raw
 Schema |             Name              |       Type        |  Owner   | Persistence | Access method |    Size    | Description 
--------+-------------------------------+-------------------+----------+-------------+---------------+------------+-------------
 public | bdadmin_communes              | table             | romulus  | permanent   | heap          | 18 MB      | 
 public | bdadmin_communes_objectid_seq | sequence          | romulus  | permanent   |               | 8192 bytes | 
 public | cnrt_iris                     | table             | romulus  | permanent   | heap          | 17 MB      | 
 public | cnrt_iris_fid_iris_seq        | sequence          | romulus  | permanent   |               | 8192 bytes | 
 public | dass_etabs_sante              | table             | romulus  | permanent   | heap          | 808 kB     | 
 public | dass_etabs_sante_fid_etab_seq | sequence          | romulus  | permanent   |               | 8192 bytes | 
 public | desserte_aggregate_iris       | table             | romulus  | permanent   | heap          | 4392 kB    | 
 public | desserte_poi                  | table             | romulus  | permanent   | heap          | 1452 MB    | 
 public | dimenc_centres                | table             | romulus  | permanent   | heap          | 72 kB      | 
 public | dimenc_centres_objectid_seq   | sequence          | romulus  | permanent   |               | 8192 bytes | 
 public | dimenc_usines                 | table             | romulus  | permanent   | heap          | 16 kB      | 
 public | dimenc_usines_objectid_seq    | sequence          | romulus  | permanent   |               | 8192 bytes | 
 public | dittt_denominations           | table             | romulus  | permanent   | heap          | 1192 kB    | 
 public | dittt_noeuds                  | table             | romulus  | permanent   | heap          | 110 MB     | 
 public | dittt_noeuds_objectid_seq     | sequence          | romulus  | permanent   |               | 8192 bytes | 
 public | dittt_segments                | table             | romulus  | permanent   | heap          | 572 MB     | 
 public | dittt_segments_objectid_seq   | sequence          | romulus  | permanent   |               | 8192 bytes | 
 public | dittt_segments_pgr            | materialized view | romulus  | permanent   | heap          | 29 MB      | 
 public | geography_columns             | view              | postgres | permanent   |               | 0 bytes    | 
 public | geometry_columns              | view              | postgres | permanent   |               | 0 bytes    | 
 public | spatial_ref_sys               | table             | postgres | permanent   | heap          | 6936 kB    | 
```

### Structures finales de l'ensemble des tables

```raw
                                         Table "public.dittt_noeuds"
    Column    |         Type          | Collation | Nullable |                    Default                     
--------------+-----------------------+-----------+----------+------------------------------------------------
 objectid     | integer               |           | not null | nextval('dittt_noeuds_objectid_seq'::regclass)
 noe_type     | character varying(3)  |           |          | 
 noe_valide   | date                  |           |          | 
 noe_vali_1   | character varying(1)  |           |          | 
 noe_guid     | character varying(36) |           |          | 
 noe_seg_su   | character varying(36) |           |          | 
 noe_seg_in   | character varying(36) |           |          | 
 created_us   | character varying(13) |           |          | 
 created_da   | date                  |           |          | 
 last_edite   | character varying(13) |           |          | 
 last_edi_1   | date                  |           |          | 
 wkb_geometry | geometry(PointZ,3163) |           |          | 
 component    | integer               |           |          | 
Indexes:
    "dittt_noeuds_pkey" PRIMARY KEY, btree (objectid)
    "dittt_noeuds_noe_guid_uniq" UNIQUE CONSTRAINT, btree (noe_guid)
    "dittt_noeuds_wkb_geometry_geom_idx" gist (wkb_geometry)
Referenced by:
    TABLE "dass_etabs_sante" CONSTRAINT "dass_etabs_sante_dittt_noeud_ref_fkey" FOREIGN KEY (dittt_noeud_ref) REFERENCES dittt_noeuds(objectid)
    TABLE "desserte_poi" CONSTRAINT "desserte_poi_source_fkey" FOREIGN KEY (source) REFERENCES dittt_noeuds(objectid)
    TABLE "desserte_poi" CONSTRAINT "desserte_poi_target_fkey" FOREIGN KEY (target) REFERENCES dittt_noeuds(objectid)
    TABLE "dimenc_centres" CONSTRAINT "dimenc_centres_dittt_noeud_ref_fkey" FOREIGN KEY (dittt_noeud_ref) REFERENCES dittt_noeuds(objectid)
    TABLE "dimenc_usines" CONSTRAINT "dimenc_usines_dittt_noeud_ref_fkey" FOREIGN KEY (dittt_noeud_ref) REFERENCES dittt_noeuds(objectid)
    TABLE "dittt_segments" CONSTRAINT "dittt_segments_seg_noe_de_fk" FOREIGN KEY (seg_noe_de) REFERENCES dittt_noeuds(noe_guid)
    TABLE "dittt_segments" CONSTRAINT "dittt_segments_seg_noe_fi_fk" FOREIGN KEY (seg_noe_fi) REFERENCES dittt_noeuds(noe_guid)

                                              Table "public.dittt_segments"
    Column    |              Type               | Collation | Nullable |                     Default                      
--------------+---------------------------------+-----------+----------+--------------------------------------------------
 objectid     | integer                         |           | not null | nextval('dittt_segments_objectid_seq'::regclass)
 seg_type     | character varying(3)            |           |          | 
 seg_revete   | character varying(2)            |           |          | 
 seg_sens_c   | character varying(2)            |           |          | 
 seg_valide   | date                            |           |          | 
 seg_vali_1   | character varying(1)            |           |          | 
 seg_nb_voi   | numeric(1,0)                    |           |          | 
 seg_origin   | character varying(6)            |           |          | 
 seg_type_a   | character varying(10)           |           |          | 
 seg_date_a   | date                            |           |          | 
 seg_select   | character varying(1)            |           |          | 
 seg_vitess   | numeric(3,0)                    |           |          | 
 seg_vite_1   | character varying(3)            |           |          | 
 seg_foncti   | character varying(2)            |           |          | 
 seg_guid     | character varying(36)           |           |          | 
 seg_noe_fi   | character varying(36)           |           |          | 
 seg_noe_de   | character varying(36)           |           |          | 
 seg_nom_gu   | character varying(36)           |           |          | 
 created_us   | character varying(13)           |           |          | 
 created_da   | date                            |           |          | 
 last_edite   | character varying(13)           |           |          | 
 last_edi_1   | date                            |           |          | 
 seg_largeu   | numeric(2,0)                    |           |          | 
 seg_larg_1   | character varying(2)            |           |          | 
 shape__len   | numeric(24,15)                  |           |          | 
 wkb_geometry | geometry(MultiLineStringZ,3163) |           |          | 
Indexes:
    "dittt_segments_pkey" PRIMARY KEY, btree (objectid)
    "dittt_segments_seg_guid_uniq" UNIQUE CONSTRAINT, btree (seg_guid)
    "dittt_segments_seg_noe_de_idx" btree (seg_noe_de)
    "dittt_segments_seg_noe_fi_idx" btree (seg_noe_fi)
    "dittt_segments_seg_type_idx" btree (seg_type)
    "dittt_segments_wkb_geometry_geom_idx" gist (wkb_geometry)
Foreign-key constraints:
    "dittt_segments_seg_noe_de_fk" FOREIGN KEY (seg_noe_de) REFERENCES dittt_noeuds(noe_guid)
    "dittt_segments_seg_noe_fi_fk" FOREIGN KEY (seg_noe_fi) REFERENCES dittt_noeuds(noe_guid)
    "dittt_segments_seg_nom_gu_fk" FOREIGN KEY (seg_nom_gu) REFERENCES dittt_denominations(nom_guid)

                      Table "public.dittt_denominations"
          Column          |       Type        | Collation | Nullable | Default 
--------------------------+-------------------+-----------+----------+---------
 objectid                 | integer           |           | not null | 
 nom_code                 | character varying |           |          | 
 nom_libelle              | character varying |           |          | 
 code_commune             | numeric           |           |          | 
 nom_libelle_commune      | character varying |           |          | 
 nom_code_commune         | numeric           |           | not null | 
 nom_libelle_proprietaire | character varying |           |          | 
 nom_code_proprietaire    | character varying |           |          | 
 globalid                 | character varying |           | not null | 
 nom_guid                 | character varying |           | not null | 
 created_user             | character varying |           |          | 
 created_date             | character varying |           |          | 
 last_edited_user         | character varying |           | not null | 
 last_edited_date         | character varying |           | not null | 
 nom_gestion              | character varying |           | not null | 
 nom_prefixe              | character varying |           |          | 
 nom_type                 | character varying |           |          | 
 nom_article              | character varying |           |          | 
 nom_suffixe              | character varying |           |          | 
 nom_titre                | character varying |           |          | 
 nom_prenom               | character varying |           |          | 
 nom_denom                | character varying |           |          | 
Indexes:
    "dittt_denominations_pkey" PRIMARY KEY, btree (objectid)
    "dittt_denominations_nom_guid_uniq" UNIQUE CONSTRAINT, btree (nom_guid)
Referenced by:
    TABLE "dittt_segments" CONSTRAINT "dittt_segments_seg_nom_gu_fk" FOREIGN KEY (seg_nom_gu) REFERENCES dittt_denominations(nom_guid)

             Materialized view "public.dittt_segments_pgr"
     Column     |         Type         | Collation | Nullable | Default 
----------------+----------------------+-----------+----------+---------
 id             | integer              |           |          | 
 source         | integer              |           |          | 
 target         | integer              |           |          | 
 seg_type       | text                 |           |          | 
 seg_sens       | character varying(2) |           |          | 
 distance       | double precision     |           |          | 
 deniv_m        | double precision     |           |          | 
 total_distance | double precision     |           |          | 
 speed          | numeric(3,0)         |           |          | 
 cost           | double precision     |           |          | 
 reverse_cost   | double precision     |           |          | 

                                           Table "public.dimenc_usines"
     Column      |         Type          | Collation | Nullable |                     Default                     
-----------------+-----------------------+-----------+----------+-------------------------------------------------
 objectid        | integer               |           | not null | nextval('dimenc_usines_objectid_seq'::regclass)
 societe         | character varying(7)  |           |          | 
 etat            | character varying(13) |           |          | 
 site            | character varying(8)  |           |          | 
 procede         | character varying(19) |           |          | 
 date_mise_      | numeric(4,0)          |           |          | 
 wkb_geometry    | geometry(Point,3163)  |           |          | 
 dittt_noeud_ref | integer               |           |          | 
Indexes:
    "dimenc_usines_pkey" PRIMARY KEY, btree (objectid)
    "dimenc_usines_site_idx" UNIQUE CONSTRAINT, btree (site)
    "dimenc_usines_wkb_geometry_geom_idx" gist (wkb_geometry)
Foreign-key constraints:
    "dimenc_usines_dittt_noeud_ref_fkey" FOREIGN KEY (dittt_noeud_ref) REFERENCES dittt_noeuds(objectid)

                                           Table "public.dimenc_centres"
     Column      |         Type          | Collation | Nullable |                     Default                      
-----------------+-----------------------+-----------+----------+--------------------------------------------------
 objectid        | integer               |           | not null | nextval('dimenc_centres_objectid_seq'::regclass)
 massif_min      | character varying(11) |           |          | 
 site_minie      | character varying(28) |           |          | 
 titulaire       | character varying(36) |           |          | 
 tacheron        | character varying(10) |           |          | 
 type_autor      | character varying(36) |           |          | 
 province        | character varying(18) |           |          | 
 commune         | character varying(20) |           |          | 
 num_arrete      | character varying(20) |           |          | 
 date_arret      | date                  |           |          | 
 num_arre_1      | character varying(20) |           |          | 
 date_arr_1      | date                  |           |          | 
 duree           | numeric(2,0)          |           |          | 
 titulaire_      | character varying(4)  |           |          | 
 wkb_geometry    | geometry(Point,3163)  |           |          | 
 dittt_noeud_ref | integer               |           |          | 
Indexes:
    "dimenc_centres_pkey" PRIMARY KEY, btree (objectid)
    "dimenc_centres_wkb_geometry_geom_idx" gist (wkb_geometry)
    "dimenc_mines_site_idx" UNIQUE CONSTRAINT, btree (site_minie)
Foreign-key constraints:
    "dimenc_centres_dittt_noeud_ref_fkey" FOREIGN KEY (dittt_noeud_ref) REFERENCES dittt_noeuds(objectid)

                                           Table "public.dass_etabs_sante"
     Column      |          Type          | Collation | Nullable |                      Default                       
-----------------+------------------------+-----------+----------+----------------------------------------------------
 fid_etab        | integer                |           | not null | nextval('dass_etabs_sante_fid_etab_seq'::regclass)
 commune         | character varying(255) |           |          | 
 type_etabli     | character varying(255) |           |          | 
 denominatio     | character varying(255) |           |          | 
 resemsej        | character varying(255) |           |          | 
 raison_soci     | character varying(255) |           |          | 
 resemseg        | character varying(255) |           |          | 
 adresse         | character varying(255) |           |          | 
 situation       | character varying(255) |           |          | 
 horaires        | character varying(255) |           |          | 
 contact_tel     | character varying(255) |           |          | 
 contact_tel2    | character varying(255) |           |          | 
 date_maj        | character varying(255) |           |          | 
 jours_ouver     | character varying(255) |           |          | 
 longitude       | character varying(255) |           |          | 
 latitude        | character varying(255) |           |          | 
 commentaire     | character varying(255) |           |          | 
 wkb_geometry    | geometry(Point,3163)   |           |          | 
 dittt_noeud_ref | integer                |           |          | 
Indexes:
    "dass_etabs_sante_pkey" PRIMARY KEY, btree (fid_etab)
    "dass_etabs_sante_wkb_geometry_geom_idx" gist (wkb_geometry)
Foreign-key constraints:
    "dass_etabs_sante_dittt_noeud_ref_fkey" FOREIGN KEY (dittt_noeud_ref) REFERENCES dittt_noeuds(objectid)


                                            Table "public.cnrt_iris"
    Column    |            Type             | Collation | Nullable |                   Default                   
--------------+-----------------------------+-----------+----------+---------------------------------------------
 fid_iris     | integer                     |           | not null | nextval('cnrt_iris_fid_iris_seq'::regclass)
 code_iris    | character varying(254)      |           |          | 
 lib_iris     | character varying(254)      |           |          | 
 code_com     | character varying(80)       |           |          | 
 nom_com      | character varying(80)       |           |          | 
 wkb_geometry | geometry(MultiPolygon,3163) |           |          | 
Indexes:
    "cnrt_iris_pkey" PRIMARY KEY, btree (fid_iris)
    "cnrt_iris_code_iris_idx" UNIQUE CONSTRAINT, btree (code_iris)
    "cnrt_iris_lib_iris_idx" UNIQUE CONSTRAINT, btree (lib_iris)
    "cnrt_iris_wkb_geometry_geom_idx" gist (wkb_geometry)
Referenced by:
    TABLE "desserte_aggregate_iris" CONSTRAINT "desserte_aggregate_iris_iris_code_fkey" FOREIGN KEY (iris_code) REFERENCES cnrt_iris(code_iris)
    TABLE "desserte_aggregate_iris" CONSTRAINT "desserte_aggregate_iris_iris_libelle_fkey" FOREIGN KEY (iris_libelle) REFERENCES cnrt_iris(lib_iris)

             Table "public.desserte_poi"
  Column  |  Type   | Collation | Nullable | Default 
----------+---------+-----------+----------+---------
 source   | integer |           | not null | 
 poi_type | text    |           | not null | 
 poi_id   | integer |           | not null | 
 target   | integer |           | not null | 
 cost     | numeric |           |          | 
Indexes:
    "desserte_poi_pkey" PRIMARY KEY, btree (poi_type, poi_id, target)
Check constraints:
    "desserte_poi_poi_type_check" CHECK (poi_type = ANY (ARRAY['dimenc_usines'::text, 'dimenc_centres'::text, 'dass_etabs_sante'::text]))
Foreign-key constraints:
    "desserte_poi_source_fkey" FOREIGN KEY (source) REFERENCES dittt_noeuds(objectid)
    "desserte_poi_target_fkey" FOREIGN KEY (target) REFERENCES dittt_noeuds(objectid)

         Table "public.desserte_aggregate_iris"
    Column    |  Type   | Collation | Nullable | Default 
--------------+---------+-----------+----------+---------
 poi_type     | text    |           | not null | 
 poi_id       | integer |           | not null | 
 poi_name     | text    |           | not null | 
 iris_code    | text    |           | not null | 
 iris_libelle | text    |           |          | 
 minimum      | numeric |           |          | 
 mediane      | numeric |           |          | 
 moyenne      | numeric |           |          | 
 maximum      | numeric |           |          | 
Indexes:
    "desserte_aggregate_iris_pkey" PRIMARY KEY, btree (poi_type, poi_id, iris_code)
Check constraints:
    "desserte_aggregate_iris_poi_type_check" CHECK (poi_type = ANY (ARRAY['dimenc_usines'::text, 'dimenc_centres'::text, 'dass_etabs_sante'::text]))
Foreign-key constraints:
    "desserte_aggregate_iris_iris_code_fkey" FOREIGN KEY (iris_code) REFERENCES cnrt_iris(code_iris)
    "desserte_aggregate_iris_iris_libelle_fkey" FOREIGN KEY (iris_libelle) REFERENCES cnrt_iris(lib_iris)

```
