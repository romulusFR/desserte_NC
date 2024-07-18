
DELETE FROM desserte_poi;

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
        dimenc_usines poi CROSS JOIN dittt_noeuds n
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

-- select count(*) from costs;
-- 662802

routes AS (
  SELECT DISTINCT source FROM dittt_segments_pgr WHERE seg_type = 'R'
  UNION
  SELECT DISTINCT target FROM dittt_segments_pgr WHERE seg_type = 'R'
)

INSERT INTO desserte_poi
    (
    SELECT
        poi.dittt_noeud_ref,
        'dimenc_usines' AS poi_type,
        poi.objectid AS poi_id,
        n.objectid,
        cost
    FROM (dimenc_usines poi CROSS JOIN dittt_noeuds n) LEFT OUTER JOIN costs c
        ON poi.dittt_noeud_ref = c.source AND n.objectid = target
    WHERE n.objectid in (SELECT * FROM routes)
    );
-- INSERT 0 192181 // avec jointure fermée
-- INSERT 0 225627 = 75209 * 3 // avec jointure ouverte sur le produit
-- Time: 3647,361 ms (00:03,647)
-- compter environ 1.21 sec / poi

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
        poi.dittt_noeud_ref,
        'dimenc_centres' AS poi_type,
        poi.objectid AS poi_id,
        n.objectid,
        cost
    FROM (dimenc_centres poi CROSS JOIN dittt_noeuds n) LEFT OUTER JOIN costs c
        ON poi.dittt_noeud_ref = c.source AND n.objectid = target
    WHERE n.objectid in (SELECT * FROM routes)
    );
-- INSERT 0 3008360
-- Time: 47252,487 ms (00:47,252)
-- compter environ 1.18 sec / poi

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
        poi.dittt_noeud_ref,
        'dass_etabs_sante' AS poi_type,
        poi.fid_etab AS poi_id,
        n.objectid,
        cost
    FROM (dass_etabs_sante poi CROSS JOIN dittt_noeuds n) LEFT OUTER JOIN costs c
        ON poi.dittt_noeud_ref = c.source AND n.objectid = target
    WHERE n.objectid in (SELECT * FROM routes)
    );