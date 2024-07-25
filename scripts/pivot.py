"""Script pour pivoter une table csv"""

import logging
from pathlib import Path
import pandas as pd

logging.basicConfig(level=logging.INFO)

dist = Path("../dist/")
# code_iris,lib_iris,type_mine,code_mine,site_mine,minimum,moyenne,maximum,mediane
for filename in (
    "desserte_mine_iris.csv",
    "desserte_etabs_sante_iris.csv",
):
    logging.info(f"Reading {filename} in {dist}")
    df_csv = pd.read_csv(dist / filename)
    path = Path(filename)

    for attribute in ["minimum", "mediane", "moyenne", "maximum"]:
        output_filename = f"{path.stem}_pivot_{attribute}{path.suffix}"
        logging.info(f"\t[{attribute}] Writing {output_filename}")
        df_csv.pivot(
            index=["iris_code", "iris_libelle"],
            columns=["poi_type", "poi_id", "poi_name"],
            values=attribute,
        ).fillna("N/A").to_csv(dist / output_filename)
