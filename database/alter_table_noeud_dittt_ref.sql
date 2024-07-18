-- les 3 requêtes sont similaires, mais on duplique le code car les tables des POI sont différentes


--------------------------------
-- POI = usines
ALTER TABLE dimenc_usines ADD COLUMN dittt_noeud_ref integer REFERENCES dittt_noeuds(objectid);

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
  select closest.objectid as ditt_noeud_ref, closest.component as cc, poi.objectid as poi_id
  from dimenc_usines poi join lateral
      (select *
        from dittt_noeuds n join large_cc using (component)
        --- la sélection aux cc qui concernent au moins 1/1000 des p+r produit 17 composantes
        where size_pc >= 0.1
        order by poi.wkb_geometry <-> n.wkb_geometry
        fetch first 1 row only
      ) closest on true
)

update dimenc_usines
set dittt_noeud_ref = n.ditt_noeud_ref
from best_neighbour n
where n.poi_id = dimenc_usines.objectid;


--------------------------------
-- POI = centres miniers (mines)
ALTER TABLE dimenc_centres ADD COLUMN dittt_noeud_ref integer REFERENCES dittt_noeuds(objectid);

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

best_neighbour as(
  select closest.objectid as ditt_noeud_ref, closest.component as cc, poi.objectid as poi_id
  from dimenc_centres poi join lateral
      (select *
        from dittt_noeuds n join large_cc using (component)
        where size_pc >= 0.1
        order by poi.wkb_geometry <-> n.wkb_geometry
        fetch first 1 row only
      ) closest on true
)

update dimenc_centres
set dittt_noeud_ref = n.ditt_noeud_ref
from best_neighbour n
where n.poi_id = dimenc_centres.objectid;


--------------------------------
-- POI = établissements de santé
ALTER TABLE dass_etabs_sante ADD COLUMN dittt_noeud_ref integer REFERENCES dittt_noeuds(objectid);

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

best_neighbour as(
  select closest.objectid as ditt_noeud_ref, closest.component as cc, poi.fid_etab as poi_id
  from dass_etabs_sante poi join lateral
      (select *
        from dittt_noeuds n join large_cc using (component)
        where size_pc >= 0.1
        order by poi.wkb_geometry <-> n.wkb_geometry
        fetch first 1 row only
      ) closest on true
)

update dass_etabs_sante
set dittt_noeud_ref = n.ditt_noeud_ref
from best_neighbour n
where n.poi_id = dass_etabs_sante.fid_etab and dass_etabs_sante.wkb_geometry is not null;

-- UPDATE 1333 (18 étab n'ont PAS de géométrie)
-- Time: 348,073 ms
