from genderComputer import GenderComputer

gc = GenderComputer()


def get_gender(first_name, middle_name):
    name = first_name
    name += " " + middle_name if len(middle_name) > 1 else ""  # Ignore middle name if empty or only a single initial
    gender = gc.resolveGender(name, "USA")
    return gender


def get_ratios(df):
    genders = list()
    for i in range(len(df)):
        f_name = str(df.loc[i, "FIRST_NAME"])
        m_name = str(df.loc[i, "MIDDLE_NAME"])
        gender = get_gender(f_name, m_name)
        genders.append(gender)

    males = genders.count("male")
    females = genders.count("female")
    unisex = genders.count("unisex")
    nones = genders.count(None)
    unknowns = unisex + nones

    male_ratio = males / len(genders)
    female_ratio = females / len(genders)
    unknown_ratio = unknowns / len(genders)

    male_ratio_mf = males / (males + females)
    female_ratio_mf = females / (males + females)

    return (male_ratio, female_ratio, unknown_ratio, male_ratio_mf, female_ratio_mf)


def print_gender_table_data(list_of_extracts):
    for name, df in list_of_extracts:
        print(name, get_ratios(df))
