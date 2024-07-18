-- les 3 requêtes sont similaires, mais on duplique le code car les tables des POI sont différentes

ALTER TABLE dimenc_usines ADD COLUMN dittt_noeud_ref integer REFERENCES dittt_noeuds(objectid);
ALTER TABLE dimenc_centres ADD COLUMN dittt_noeud_ref integer REFERENCES dittt_noeuds(objectid);
ALTER TABLE dass_etabs_sante ADD COLUMN dittt_noeud_ref integer REFERENCES dittt_noeuds(objectid);

--------------------------------
-- POI = usines


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
  from dimenc_usines poi join lateral
      (select *
        from dittt_noeuds n join large_cc using (component)
        --- la sélection aux cc qui concernent au moins 1/10000 des p+r produit 17 composantes
        where size_pc >= 0.01
        order by poi.wkb_geometry <-> n.wkb_geometry
        fetch first 1 row only
      ) closest on true
)

update dimenc_usines
set dittt_noeud_ref = n.dittt_noeud_ref
from best_neighbour n
where n.poi_id = dimenc_usines.objectid;


--------------------------------
-- POI = centres miniers (mines)


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
  select closest.objectid as dittt_noeud_ref, closest.component as cc, poi.objectid as poi_id
  from dimenc_centres poi join lateral
      (select *
        from dittt_noeuds n join large_cc using (component)
        where size_pc >= 0.01
        order by poi.wkb_geometry <-> n.wkb_geometry
        fetch first 1 row only
      ) closest on true
)

update dimenc_centres
set dittt_noeud_ref = n.dittt_noeud_ref
from best_neighbour n
where n.poi_id = dimenc_centres.objectid;


--------------------------------
-- POI = établissements de santé


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
  select closest.objectid as dittt_noeud_ref, closest.component as cc, poi.fid_etab as poi_id
  from dass_etabs_sante poi join lateral
      (select *
        from dittt_noeuds n join large_cc using (component)
        where size_pc >= 0.01
        order by poi.wkb_geometry <-> n.wkb_geometry
        fetch first 1 row only
      ) closest on true
)

update dass_etabs_sante
set dittt_noeud_ref = n.dittt_noeud_ref
from best_neighbour n
where n.poi_id = dass_etabs_sante.fid_etab and dass_etabs_sante.wkb_geometry is not null;

-- UPDATE 1333 (18 étab n'ont PAS de géométrie)
-- Time: 348,073 ms
