# Retour d'expérience sur la reprise du calcul de desserte

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
- Possible faire base QGIS programmatique via xml ou Python poru échaffauder des projets de départ.
