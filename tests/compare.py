"""Comparaison valeurs 2021 et 2024"""

# %%
import pandas as pd

data_2021 = pd.read_csv("2021-desserte_mine_iris.csv")
data_2024 = pd.read_csv("2024-desserte_mine_iris.csv")


data_2021["type_mine"] = (
    data_2021["type_mine"]
    .str.replace("usine", "dimenc_usines")
    .str.replace("centre", "dimenc_centres")
)
mapper = {
    "code_iris": "iris_code",
    "lib_iris": "iris_libelle",
    "type_mine": "poi_type",
    "code_mine": "poi_id",
    "site_mine": "poi_name",
}
data_2021.rename(mapper, axis="columns", inplace=True)
data_2021.drop(columns=["iris_libelle", "poi_name"], inplace=True)
# %%

data_cmp = data_2021.merge(
    data_2024, on=["iris_code", "poi_type", "poi_id"], suffixes=("_2021", "_2024")
)

aggs = ("minimum", "mediane", "moyenne", "maximum")
postfix = "2021-2024"
for attr in aggs:
    data_cmp[f"{attr}_{postfix}"] = data_cmp[f"{attr}_2021"] - data_cmp[f"{attr}_2024"]

# %%
data_cmp[
    ["iris_code", "iris_libelle", "poi_type", "poi_id", "poi_name"]
    + [f"{attr}_{postfix}" for attr in aggs]
].sort_values(f"mediane_{postfix}").to_csv(
    "difference-2021-2024-desserte_mine_iris.csv"
)
