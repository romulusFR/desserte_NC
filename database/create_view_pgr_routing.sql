DROP MATERIALIZED VIEW IF EXISTS dittt_segments_pgr;
CREATE MATERIALIZED VIEW dittt_segments_pgr AS(
  SELECT
    e.objectid::integer AS id,
    src.objectid::integer AS "source",
    tgt.objectid::integer AS "target",
    -- e.seg_type AS seg_type,
    CASE
        WHEN e.seg_type IN ('VCU', 'VCS', 'B', 'VR', 'A', 'RP') THEN 'R'
        WHEN e.seg_type IN ('P') THEN 'P'
        ELSE 'X'
    END AS seg_type,
    e.seg_sens_c AS seg_sens,
    ROUND(ST_Length(e.wkb_geometry)) AS distance,
    ABS(ROUND(ST_Z(tgt.wkb_geometry) - ST_Z(src.wkb_geometry))) AS deniv_m,
-- ROUND(100*(ST_Z(tgt.wkb_geometry) - ST_Z(src.wkb_geometry))/ST_Length(e.wkb_geometry)) AS deniv_pc,
    sqrt(power(ST_Length(e.wkb_geometry), 2) + power(ST_Z(tgt.wkb_geometry) - ST_Z(src.wkb_geometry), 2)) AS total_distance,
    e.seg_vitess AS speed,
    CASE e.seg_sens_c
        WHEN 'D' THEN sqrt(power(ST_Length(e.wkb_geometry), 2) + power(ST_Z(tgt.wkb_geometry) - ST_Z(src.wkb_geometry), 2)) / (1000*seg_vitess/3600)
        WHEN 'SV' THEN sqrt(power(ST_Length(e.wkb_geometry), 2) + power(ST_Z(tgt.wkb_geometry) - ST_Z(src.wkb_geometry), 2)) / (1000*seg_vitess/3600)
        ELSE -1
    END  AS "cost",
    CASE e.seg_sens_c
        WHEN 'D' THEN sqrt(power(ST_Length(e.wkb_geometry), 2) + power(ST_Z(tgt.wkb_geometry) - ST_Z(src.wkb_geometry), 2)) / (1000*seg_vitess/3600)
        WHEN 'SO' THEN sqrt(power(ST_Length(e.wkb_geometry), 2) + power(ST_Z(tgt.wkb_geometry) - ST_Z(src.wkb_geometry), 2)) / (1000*seg_vitess/3600)
        ELSE -1
    END  AS "reverse_cost",
    e.wkb_geometry AS geom
  FROM dittt_segments e
    JOIN dittt_noeuds src ON e.seg_noe_de = src.noe_guid
    JOIN dittt_noeuds tgt ON e.seg_noe_fi = tgt.noe_guid
);