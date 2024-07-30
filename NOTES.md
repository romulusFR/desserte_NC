# Retour d'expérience sur la reprise du calcul de desserte

## Points de friction

Entre la réalisation en 2021 et la reprise en 2024, on note les points de frictions et les difficultés rencontrées.

- Assez laborieux de trouver les liens (génération), télécharger, copier sur le serveur et enfin importer.
- Problème d'attributs renommés ou tronqués au changement de version dans la BD. Limite intrinsèque des _ESRI Shapefile_ à 10.
- Encodage des caractères et _slugification_.
- Données manquantes ou erronées (e.g., rue Mayer à Thio)
- Conventions de nommage URLs/archives/fichiers/tables/calques QGis.
- Avoir des fichiers de métadonnées exploitables programmatiquement, pas du pdf, voir les `.xml` de l'IGN.
  - Existe, mais je ne sais pas les utiliser, pas poru la recherche en tout cas
- Automatisation pour changement d'environnement, notamment le déploiement au serveur.
- Comment faire suivre les références aux sources utilisées (db, .shp, wms) dans QGis, comment avoir _un cache_ de l'instant t.
- Possible faire base QGIS programmatique via xml ou Python pour _scaffold__ des projets de départ.
- Scripting / full auto : quel env, vérifier d'une màj à l'autre.
- J'ai moi-même changé les formats : car ils sont mieux ! Hypothèse _après c'est mieux ?_ : le format pivot est le plus récent ? mais en pratique... le moins disant !
- Toujours laisser la présentation à la présentation : typographie, arrondi/conversion entier.

## TODO pour gérer POI

- [ ] Voir à remplacer `desserte_aggregate_iris` et `desserte_poi` par des vues matérialisées, ou en tout cas voir la question des mises à jour.
- [ ] Voir pourquoi quasiment aucun parallélisme, même pour les agrégats finaux.
- [ ] Voir à utiliser les noms des relations comme catégories des POI et une catégorie existante comme une sous-catégorie, e.g., `type_etabli` pour les établissements de santé.
  - En particulier, car cela fait porter l'agrégat sur le sous-ensemble des catégories qu'on ne sait plus séparer après.
- [ ] Voir une notion d'héritage des tables de POI d'une table abstraite avec les attributs communs, car `poi_type` est proche d'un codage de l'héritage.
