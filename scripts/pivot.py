"""Script pour pivoter une table csv"""

import pandas as pd
from pathlib import Path

# code_iris,lib_iris,type_mine,code_mine,site_mine,minimum,moyenne,maximum,mediane

for filename in (
    "../dist/desserte_mine_iris.csv",
    "../dist/desserte_etabs_sante_iris.csv",
):
    df_csv = pd.read_csv(filename)
    path = Path(filename)

    for attribute in ["minimum", "mediane", "moyenne", "maximum"]:
        output_filename = f"{path.stem}_pivot_{attribute}{path.suffix}"
        df_csv.pivot(
            index=["iris_code", "iris_libelle"],
            columns=["poi_type", "poi_id", "poi_name"],
            values=attribute,
        ).fillna("N/A").to_csv(output_filename)
