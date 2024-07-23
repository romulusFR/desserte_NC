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
        dimenc_centres poi CROSS JOIN dittt_noeuds n
      WHERE
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
        'dimenc_centres' AS poi_type,
        poi.objectid AS poi_id,
        c.target AS target,
        cost AS cost
    FROM dimenc_centres poi JOIN costs c ON poi.dittt_noeud_ref = c.source
    WHERE c.target IN (SELECT * FROM routes)
    );
-- INSERT 0 2498401 // avec jointure "fermée"
-- Time: 34566,934 ms (00:34,567)
-- environ 0.86 sec / POI
-- INSERT 0 3008360 // avec jointure ouverte sur le produit
-- Time: 47252,487 ms (00:47,252)
-- environ 1.18 sec / POI
