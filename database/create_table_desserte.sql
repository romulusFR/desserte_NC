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


DROP TABLE IF EXISTS desserte_aggregate_iris;
CREATE TABLE desserte_aggregate_iris (
  -- type du POI = la table d'intérêt
  poi_type text CHECK (poi_type IN ( 'dimenc_usines', 'dimenc_centres', 'dass_etabs_sante')),
  -- pas de clef ici, car on peut pointer sur 3 tables différentes
  poi_id int NOT NULL,
  -- un nom usuel du POI
  poi_name text NOT NULL, 
  -- références vers les IRIS
  iris_code text REFERENCES cnrt_iris(code_iris),
  iris_libelle text REFERENCES cnrt_iris(lib_iris),
  -- les résultats du calcul qu'on matérialise
  minimum numeric NULL,
  mediane numeric NULL,
  moyenne numeric NULL,
  maximum numeric NULL,
  PRIMARY KEY (poi_type, poi_id, iris_code)
);


