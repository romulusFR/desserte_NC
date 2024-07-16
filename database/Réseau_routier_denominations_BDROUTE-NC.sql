-- schéma de relation postgres associé aux dénominations des
-- voies de BDROUTE, voir :
-- <https://georep-dtsi-sgt.opendata.arcgis.com/maps/d3915082450a4405bb30dda99e19bc61/about>

CREATE TABLE IF NOT EXISTS dittt_denominations (
        objectid INTEGER PRIMARY KEY, 
        nom_code VARCHAR, 
        nom_libelle VARCHAR, 
        code_commune DECIMAL, 
        nom_libelle_commune VARCHAR, 
        nom_code_commune DECIMAL NOT NULL, 
        nom_libelle_proprietaire VARCHAR, 
        nom_code_proprietaire VARCHAR, 
        globalid VARCHAR NOT NULL, 
        nom_guid VARCHAR NOT NULL, 
        created_user VARCHAR, 
        created_date VARCHAR, 
        last_edited_user VARCHAR NOT NULL, 
        last_edited_date VARCHAR NOT NULL, 
        nom_gestion VARCHAR NOT NULL, 
        nom_prefixe VARCHAR, 
        nom_type VARCHAR, 
        nom_article VARCHAR, 
        nom_suffixe VARCHAR, 
        nom_titre VARCHAR, 
        nom_prenom VARCHAR, 
        nom_denom VARCHAR
);
