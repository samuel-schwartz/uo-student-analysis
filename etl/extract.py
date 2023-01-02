import pandas as pd
import os

def extract_deans_lists():
    """
    Extracts dean's list data from files

    Returns:
        list[(filename, pandas.DataFrame)]: List of tuples with two elements. 
        The first element is a string with the filename. The second element is a pandas dataframe of the file.
    """
    
    path = "data/deans_lists/"
    list_of_files = []

    for root, dirs, files in os.walk(path):
        for file in files:
            if file.endswith(".xls") or file.endswith(".xlsx"):
                list_of_files.append(os.path.join(root, file))

    deans_lists = list()
    for name in list_of_files:
        deans_lists.append((name, pd.read_excel(name)))

    return deans_lists


