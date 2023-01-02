from etl.extract import extract_deans_lists
from etl.gender_differences import print_gender_table_data
from etl.majors import print_major_table_data
from etl.zip_code import run_pipeline
print("External Libraries Loaded")


print("Extracting Data From Excel Files")
extraction_data = extract_deans_lists()
#print("Printing Gender Data")
#print_gender_table_data(extraction_data)
#print_major_table_data(extraction_data)
run_pipeline(extraction_data)