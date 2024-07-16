-- ajout des clefs alternatives sur le réseau routier DITTT
ALTER TABLE dittt_noeuds ADD CONSTRAINT dittt_noeuds_noe_guid_uniq UNIQUE (noe_guid);
ALTER TABLE dittt_segments ADD CONSTRAINT dittt_segments_seg_guid_uniq UNIQUE (seg_guid);

-- correction d'erreur sur un segment sans noeud de fin
UPDATE dittt_segments
SET seg_noe_fi = 'cb25cb2e-e46b-43b2-8a6c-8d56b4bd5d45'
WHERE seg_guid = 'f4c51098-52f1-4007-a1e9-762f1d5f01a5';
-- UPDATE 1

-- ajout des clefs étrangères : chaque segment a un noeud de départ et un de fin
ALTER TABLE dittt_segments ADD CONSTRAINT dittt_segments_seg_noe_fi_fk
  FOREIGN KEY (seg_noe_fi) REFERENCES dittt_noeuds(noe_guid);
ALTER TABLE dittt_segments ADD CONSTRAINT dittt_segments_seg_noe_de_fk
  FOREIGN KEY (seg_noe_de) REFERENCES dittt_noeuds(noe_guid);

-- indexation
CREATE INDEX dittt_segments_seg_noe_fi_idx ON dittt_segments(seg_noe_fi);
CREATE INDEX dittt_segments_seg_noe_de_idx ON dittt_segments(seg_noe_de);
CREATE INDEX dittt_segments_seg_type_idx ON dittt_segments(seg_type);

-- remplacement du UUID 00000000-0000-0000-0000-000000000000 par NULL pour les segments sans dénomination
UPDATE dittt_segments
SET seg_nom_gu = NULL
WHERE seg_nom_gu = '00000000-0000-0000-0000-000000000000' ;
-- UPDATE 276181
-- correction d'erreur sur un segment sans dénomination
UPDATE dittt_segments
SET seg_nom_gu = '58061508-dfee-478d-b6d1-234615df095b'
WHERE seg_guid = '23dd409a-e754-49fd-aaaf-dfc0f22c487d';
-- UPDATE 1

-- ajout des clefs alternatives sur les dénomniations du réseau routier DITTT
ALTER TABLE dittt_denominations ADD CONSTRAINT dittt_denominations_nom_guid_uniq UNIQUE (nom_guid);

-- ajout des clefs étrangères : chaque segment a une dénomination
ALTER TABLE dittt_segments ADD CONSTRAINT dittt_segments_seg_nom_gu_fk
  FOREIGN KEY (seg_nom_gu) REFERENCES dittt_denominations(nom_guid);

-- ajout des clefs alternatives sur les sites miniers (centres et usines)
ALTER TABLE dimenc_centres ADD CONSTRAINT dimenc_mines_site_idx UNIQUE(site_minie);
ALTER TABLE dimenc_usines ADD CONSTRAINT dimenc_usines_site_idx UNIQUE(site);


-- ajout des clefs alternatives sur les IRIS
ALTER TABLE cnrt_iris ADD CONSTRAINT cnrt_iris_code_iris_idx UNIQUE(code_iris);
ALTER TABLE cnrt_iris ADD CONSTRAINT cnrt_iris_lib_iris_idx UNIQUE(lib_iris);
