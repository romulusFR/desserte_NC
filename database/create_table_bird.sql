-- idem create_table_desserte.sql mais avec "bird" pour le vol d'oiseau
drop table if exists bird_poi;

create table bird_poi(
  source int not null references dittt_noeuds(objectid),
  poi_type text check (poi_type in ('dimenc_usines', 'dimenc_centres', 'dass_etabs_sante')),
  poi_id int not null,
  target int references dittt_noeuds(objectid),
  cost numeric null,
  primary key (poi_type, poi_id, target)
);

drop table if exists bird_aggregate_iris;

create table bird_aggregate_iris(
  poi_type text check (poi_type in ('dimenc_usines', 'dimenc_centres', 'dass_etabs_sante')),
  poi_id int not null,
  poi_name text not null,
  iris_code text references cnrt_iris(code_iris),
  iris_libelle text references cnrt_iris(lib_iris),
  minimum numeric null,
  mediane numeric null,
  moyenne numeric null,
  maximum numeric null,
  primary key (poi_type, poi_id, iris_code)
);

