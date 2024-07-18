with large_cc as(
  select
    component,
    count(*) as size_cc,
    100*count(*)::numeric / (select count(*) from dittt_noeuds where component is not null) as size_pc
  from dittt_noeuds
  where component is not null
  group by component
  --- la sélection aux cc qui concernent au moins 1/1000 des p+r produit 17 composantes
  having 100*count(*)::numeric / (select count(*) from dittt_noeuds where component is not null) >= 0.1
  order by size_cc desc
),

-- calcul du noeud DITTT le plus proche du POI
-- voir https://www.postgis.net/workshops/postgis-intro/knn.html pour le calcul
best_neighbour as(
  select closest.objectid as ditt_noeud_ref, closest.component as cc, poi.fid_etab as poi_id, closest.component
  from dass_etabs_sante poi join lateral
      (select *
        from dittt_noeuds n join large_cc using (component)
        
        
        order by poi.wkb_geometry <-> n.wkb_geometry
        fetch first 1 row only
      ) closest on true
  where poi.wkb_geometry is not null
)

select component, count(*) as nb
from best_neighbour
group by component;