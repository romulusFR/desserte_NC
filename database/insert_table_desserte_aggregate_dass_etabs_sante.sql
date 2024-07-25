WITH aggregates AS (
  SELECT
    'dass_etabs_sante' AS poi_type,
    poi.fid_etab AS poi_id,
    poi.denominatio || ' (' || poi.type_etabli || ')' AS poi_name,
    i.code_iris AS iris_core,
    i.lib_iris AS iris_libelle,
    MIN(d.cost)/60 AS minimum,
    percentile_disc(0.5) WITHIN GROUP (ORDER BY d.cost/60) AS mediane,
    AVG(d.cost)/60 AS moyenne,
    MAX(d.cost)/60 AS maximum
  FROM 
    (dass_etabs_sante poi CROSS JOIN cnrt_iris i)
    LEFT OUTER JOIN (
    (SELECT * FROM desserte_poi WHERE poi_type = 'dass_etabs_sante') d
      JOIN dittt_noeuds n ON d.target = n.objectid)
      ON ST_Contains(i.wkb_geometry, n.wkb_geometry) AND d.poi_id = poi.fid_etab
  WHERE poi.wkb_geometry IS NOT NULL AND
        poi.type_etabli IN ('Dispensaire', 'Hôpitaux', 'Pharmacie', 'Sage-Femme')
  GROUP BY poi.fid_etab, i.fid_iris
  ORDER BY poi.fid_etab, i.code_iris
)
INSERT INTO desserte_aggregate_iris (SELECT * FROM aggregates)
;