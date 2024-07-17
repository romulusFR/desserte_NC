ALTER TABLE dittt_noeuds ADD COLUMN component integer;

-- calcul des des composantes connexes utilisables par route ou piste
WITH cc AS(
    SELECT n.objectid AS objectid, c.component
    FROM dittt_noeuds n
        JOIN pgr_connectedComponents('SELECT * FROM dittt_segments_pgr WHERE seg_type IN (''R'', ''P'')') c
            ON c.node =  n.objectid
)

UPDATE dittt_noeuds
SET component = cc.component
FROM cc
WHERE cc.objectid = dittt_noeuds.objectid;

-- UPDATE 247732
-- Time: 8063,709 ms (00:08,064)
