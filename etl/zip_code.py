import pandas as pd
from .gender_differences import get_gender


def run_pipeline(extraction_data):
    students = consolidate_students(extraction_data)
    students = assign_gender(students)
    zip_to_zcta = pd.read_csv("data/OregonZIPtoZCTA.csv")
    df = aggregate_by_zipcode(students, zip_to_zcta)
    df = augment_census_data(df, zip_to_zcta)

    print(df)

    df.to_csv("data/student_zip_census.csv", index=False, float_format=int)

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
    df = df[df.apply(lambda row: row.ZIP_CLEAN[:2] == "97" or row.ZIP_CLEAN == "89421" or row.ZIP_CLEAN == "99362", axis=1)]  # Filter out non-US ZIPs
    df = df.sort_values(by=["LAST_NAME", "FIRST_NAME", "TERM"])

    # Of the duplicated names, use first ZIP
    df = df.drop_duplicates(subset=['LAST_NAME', 'FIRST_NAME', 'MIDDLE_NAME', 'ZIP_CLEAN'])
    df = df.drop_duplicates(subset=['LAST_NAME', 'FIRST_NAME', 'MIDDLE_NAME'])

    df = df.drop(['TERM', 'CLASS', 'MAJOR', 'ZIP', 'ZIP_CODE'], axis=1)

    print("students")
    print(df)

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


def aggregate_by_zipcode(df, zip_to_zcta):
    # df = df.groupby('ZIP_CLEAN').agg('min')
    df_pop = df.groupby(['ZIP_CLEAN']).size().reset_index(name='UO_STUDENTS')
    df_gen = df.groupby(['ZIP_CLEAN', 'GENDER']).size().reset_index(name='count')
    df_gen = pd.pivot(df_gen, index='ZIP_CLEAN', columns='GENDER', values='count').fillna(0)
    df = df_pop.merge(df_gen, on='ZIP_CLEAN')
    df["UO_MEN"] = df.apply(lambda row: int(round((row.male / (row.male + row.female)) * row.UO_STUDENTS)) if (row.male + row.female) > 0 else 0, axis=1)
    df["UO_WOMEN"] = df.apply(lambda row: int(round((row.female / (row.male + row.female)) * row.UO_STUDENTS)) if (row.male + row.female) > 0 else 0, axis=1)
    df = df.drop(['female', 'male', 'unknown'], axis=1)

    # Convert from ZIP to ZCTA
    
    zip_to_zcta = zip_to_zcta[["ZIP_CODE", "ZCTA"]]
    df = df.rename(columns={'ZIP_CLEAN': 'ZIP_CODE'})
    df["ZIP_CODE"] = df.apply(lambda row: int(row.ZIP_CODE), axis=1)
    zip_to_zcta["ZIP_CODE"] = zip_to_zcta.apply(lambda row: int(row.ZIP_CODE), axis=1)
    df = df.merge(zip_to_zcta, on="ZIP_CODE")
    df = df.groupby(by=["ZCTA"]).sum().reset_index(level=0)
    df = df.drop(['ZIP_CODE'], axis=1)
    return df

def augment_census_data(student_df, zip_to_zcta):
    """_summary_
    Augment the following fields to each ZIP df
    POP_TOTAL
    WHT_TOTAL
    POC_TOTAL
    POP_YOUTH_TOTAL
    WHT_YOUTH_TOTAL
    POC_YOUTH_TOTAL
    POP_YOUTH_MEN_TOTAL
    WHT_YOUTH_MEN_TOTAL
    POC_YOUTH_MEN_TOTAL
    POP_YOUTH_WOMEN_TOTAL
    WHT_YOUTH_WOMEN_TOTAL
    POC_YOUTH_WOMEN_TOTAL
    """

    # Get and clean all the census data
    pop = pd.read_csv("data/pop/pop.csv")
    wht = pd.read_csv("data/wht/wht.csv")

    pop = clean_raw_dta_pop(pop)
    wht = clean_raw_dta_wht(wht)

    df = pop.merge(wht, on="NAME", how="right")

    df["NAME"] = df.apply(lambda row: int(row.NAME[-5:]), axis=1)

    df = df.apply(pd.to_numeric)
    df = df.drop_duplicates()
    df = add_poc_data(df)
    df = df.rename(columns={'NAME': 'ZCTA'})

    # Merge the student data to the census data
    df = df.merge(student_df, on="ZCTA", how="left").fillna(0)

    # Add back a PO Name to the ZCTA
    df = df.merge(zip_to_zcta[["PO_NAME", "ZCTA"]].drop_duplicates(subset=['ZCTA']), on="ZCTA", how="left")
    po_names = df.pop("PO_NAME")
    df.insert(1, "CITY", po_names)
    df = df.drop_duplicates()

    return df

def clean_raw_dta_pop(df):
    # Get ZIP

    # === CODES for POP ===
    # S0101_C01_001E	Estimate!!Total!!Total population
    # S0101_C01_021E	Estimate!!Total!!Total population!!SELECTED AGE CATEGORIES!!15 to 17 years
    # S0101_C03_021E	Estimate!!Male!!Total population!!SELECTED AGE CATEGORIES!!15 to 17 years
    # S0101_C05_021E	Estimate!!Female!!Total population!!SELECTED AGE CATEGORIES!!15 to 17 years
    df = df[["NAME", "S0101_C01_001E", "S0101_C01_021E", "S0101_C03_021E", "S0101_C05_021E"]]
    df = df.rename(columns={'S0101_C01_001E': 'POP_TOTAL', 'S0101_C01_021E': 'POP_YOUTH_TOTAL', 'S0101_C03_021E': 'POP_YOUTH_MEN_TOTAL', 'S0101_C05_021E': 'POP_YOUTH_WOMEN_TOTAL'})
    
    # Drop subheader, Drop all of Oregon information
    df = df.drop(index=[0, 1])

    return df

def clean_raw_dta_wht(df_wht):
    # === CODES for WHT ===
    # B01001H_001E	Estimate!!Total:
    # B01001H_006E	Estimate!!Total:!!Male:!!15 to 17 years
    # B01001H_021E	Estimate!!Total:!!Female:!!15 to 17 years
    
    df = df_wht[["NAME", "B01001H_001E", "B01001H_006E", "B01001H_021E"]]
    df = df.rename(columns={'B01001H_001E': 'WHT_TOTAL', 'B01001H_006E': 'WHT_YOUTH_MEN_TOTAL', 'B01001H_021E': 'WHT_YOUTH_WOMEN_TOTAL'})

    # Drop subheader
    df = df.drop(index=0)

    df.insert(2, "WHT_YOUTH_TOTAL", df.apply(lambda row: int(row.WHT_YOUTH_MEN_TOTAL) + int(row.WHT_YOUTH_WOMEN_TOTAL), axis=1))

    return df

def add_poc_data(df):

    df["POC_TOTAL"] = df.apply(lambda row: max(0, int(row.POP_TOTAL) - int(row.WHT_TOTAL)), axis=1)
    df["POC_YOUTH_TOTAL"] = df.apply(lambda row: max(0, int(row.POP_YOUTH_TOTAL) - int(row.WHT_YOUTH_TOTAL)), axis=1)
    df["POC_YOUTH_MEN_TOTAL"] = df.apply(lambda row: max(0, int(row.POP_YOUTH_MEN_TOTAL) - int(row.WHT_YOUTH_MEN_TOTAL)), axis=1)
    df["POC_YOUTH_WOMEN_TOTAL"] = df.apply(lambda row: max(0, int(row.POP_YOUTH_WOMEN_TOTAL) - int(row.WHT_YOUTH_WOMEN_TOTAL)), axis=1)
    
    return df