DROP TABLE IF EXISTS desserte_poi;
CREATE TABLE desserte_poi (
  -- source doit être le dittt_noeud_ref associé à la table du poi_type
  source int NOT NULL REFERENCES dittt_noeuds(objectid),
  -- type du POI = la table d'intérêt
  poi_type text CHECK (poi_type IN ( 'dimenc_usines', 'dimenc_centres', 'dass_etabs_sante')),
  -- pas de clef ici, car on peut pointer sur 3 tables différentes
  poi_id int NOT NULL,
  -- un noeud DITTT, sera regroupé par IRIS in fine
  target int REFERENCES dittt_noeuds(objectid),
  -- le résultat du calcul qu'on matérialise
  cost numeric NULL,
  PRIMARY KEY (poi_type, poi_id, target)
);
