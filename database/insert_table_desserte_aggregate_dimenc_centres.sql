WITH aggregates AS (
  SELECT
    'dimenc_centres' AS poi_type,
    poi.objectid AS poi_id,
    poi.titulaire || ' - ' || poi.site_minie AS poi_name,
    i.code_iris AS iris_code,
    i.lib_iris AS iris_libelle,
    ROUND(MIN(d.cost)/60)::integer AS minimum,
    ROUND(percentile_disc(0.5) WITHIN GROUP (ORDER BY d.cost/60))::integer AS mediane,
    ROUND(AVG(d.cost)/60)::integer AS moyenne,
    ROUND(MAX(d.cost)/60)::integer AS maximum
  FROM 
    (dimenc_centres poi CROSS JOIN cnrt_iris i)
    LEFT OUTER JOIN (
    (SELECT * FROM desserte_poi WHERE poi_type = 'dimenc_centres') d
      JOIN dittt_noeuds n ON d.target = n.objectid)
      ON ST_Contains(i.wkb_geometry, n.wkb_geometry) AND d.poi_id = poi.objectid
  GROUP BY poi.objectid, i.fid_iris
  ORDER BY poi.objectid, i.code_iris
)
INSERT INTO desserte_aggregate_iris (SELECT * FROM aggregates)
;