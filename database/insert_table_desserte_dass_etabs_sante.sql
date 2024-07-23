-- /!\ ON SE LIMITE DANS UN PREMIER TEMP AUX TYPES SUIVANTS /!\ 
-- poi.type_etabli IN ('Dispensaire', 'Hôpitaux', 'Pharmacie', 'Sage-Femme')  AND
-- qui représentent 150 établissements pour éviter l'explosion en mémoire

--  type_etabli | nb 
-----------+----
--  Pharmacie   | 73
--  Sage-Femme  | 34
--  Hôpitaux    |  9
--  Dispensaire | 34


WITH costs as(
  SELECT
    start_vid as source,
    end_vid as target,
    agg_cost as cost
  FROM pgr_dijkstraCost(
    'SELECT * FROM dittt_segments_pgr',
    'SELECT
        poi.dittt_noeud_ref as "source",
        n.objectid::integer as "target"
      FROM
        dass_etabs_sante poi CROSS JOIN dittt_noeuds n
      WHERE
        poi.wkb_geometry IS NOT NULL AND
        poi.type_etabli IN (''Dispensaire'', ''Hôpitaux'', ''Pharmacie'', ''Sage-Femme'') AND
        n.objectid IN(
          SELECT DISTINCT source FROM dittt_segments_pgr WHERE seg_type = ''R''
          UNION
          SELECT DISTINCT target FROM dittt_segments_pgr WHERE seg_type = ''R''
        )
      ',
      TRUE
    )
),

routes AS (
  SELECT DISTINCT source FROM dittt_segments_pgr WHERE seg_type = 'R'
  UNION
  SELECT DISTINCT target FROM dittt_segments_pgr WHERE seg_type = 'R'
)

INSERT INTO desserte_poi
    (
    SELECT
        poi.dittt_noeud_ref AS source,
        'dass_etabs_sante' AS poi_type,
        poi.fid_etab AS poi_id,
        c.target AS target,
        cost AS cost
    FROM dass_etabs_sante poi JOIN costs c ON poi.dittt_noeud_ref = c.source
    WHERE c.target IN (SELECT * FROM routes) AND
          poi.wkb_geometry IS NOT NULL AND
          poi.type_etabli IN ('Dispensaire', 'Hôpitaux', 'Pharmacie', 'Sage-Femme')
    );

-- INSERT 0 8686864
-- Time: 122602,529 ms (02:02,603)
-- Time: 119123,682 ms (01:59,124)
-- environ 0.80 sec / POI