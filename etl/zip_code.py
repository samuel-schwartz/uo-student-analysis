import pandas as pd
from .gender_differences import get_gender


def run_pipeline(extraction_data):
    students = consolidate_students(extraction_data)
    students = assign_gender(students)
    dta = aggregate_by_zipcode(students)
    pass


def _zip_merger(row):
    z1 = str(row.ZIP)
    z2 = str(row.ZIP_CODE)
    if len(z1) >=5:
        return z1[:5]
    elif len(z2) >=5:
        return z2[:5]
    else:
        print("PROBLEMATIC ZIP:", row)
        return "00000"


def consolidate_students(list_of_extracts):
    df = pd.concat([df for _, df in list_of_extracts])
    df = df[df['STATE'] == "OR"]
    df['ZIP_CLEAN'] = df.apply(lambda row: _zip_merger(row), axis=1)
    df = df[df.apply(lambda row: row.ZIP_CLEAN[:2] == "97" or row.ZIP_CLEAN[:2] == "89421", axis=1)]  # Filter out non-US ZIPs
    df = df.sort_values(by=["LAST_NAME", "FIRST_NAME", "TERM"])

    # Of the duplicated names, use first ZIP
    df = df.drop_duplicates(subset=['LAST_NAME', 'FIRST_NAME', 'MIDDLE_NAME', 'ZIP_CLEAN'])
    df = df.drop_duplicates(subset=['LAST_NAME', 'FIRST_NAME', 'MIDDLE_NAME'])

    df = df.drop(['TERM', 'CLASS', 'MAJOR', 'ZIP', 'ZIP_CODE'], axis=1)

    return df


def _gender_helper(row):
    val = get_gender(str(row.FIRST_NAME), str(row.MIDDLE_NAME))
    val = str(val)
    if val == "None" or val == "unisex":
        val = "unknown"
    return val


def assign_gender(df):
    df['GENDER'] = df.apply(lambda row: _gender_helper(row), axis=1)
    return df


def aggregate_by_zipcode(df):
    # df = df.groupby('ZIP_CLEAN').agg('min')
    df_pop = df.groupby(['ZIP_CLEAN']).size().reset_index(name='UO_STUDENTS')
    df_gen = df.groupby(['ZIP_CLEAN', 'GENDER']).size().reset_index(name='count')
    df_gen = pd.pivot(df_gen, index='ZIP_CLEAN', columns='GENDER', values='count').fillna(0)
    df = df_pop.merge(df_gen, on='ZIP_CLEAN')
    df["UO_MEN"] = df.apply(lambda row: int(round((row.male / (row.male + row.female)) * row.UO_STUDENTS)) if (row.male + row.female) > 0 else 0, axis=1)
    df["UO_WOMEN"] = df.apply(lambda row: int(round((row.female / (row.male + row.female)) * row.UO_STUDENTS)) if (row.male + row.female) > 0 else 0, axis=1)
    df = df.drop(['female', 'male', 'unknown'], axis=1)

    print(df)
    return df

def augment_census_data():
    pass

