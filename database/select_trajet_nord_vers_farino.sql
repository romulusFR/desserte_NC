with q as (
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
    TRUE) AS direction)
select min(agg_cost)/60, max(agg_cost)/60, avg(agg_cost)/60 from q;
