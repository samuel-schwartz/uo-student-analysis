import numpy as np

def print_major_table_data(list_of_extracts):
    # GOAL: Determine which majors / departments produce a lot of Dean's List students.
    
    # PART 1:
    val_counts_list = list()
    for name, df in list_of_extracts:
        val_counts = df['MAJOR'].value_counts().to_dict()
        val_counts_list.append(sorted(val_counts.values()))

    # PART 2:

    # Print R code for visualization
    c_dict = dict()

    for i, (vc, (name, _)) in enumerate(zip(val_counts_list, list_of_extracts)):
        c_data = ", ".join([str(v) for v in vc])
        c_name = "academic_year_" + ''.join(filter(lambda i: i.isdigit(), name))  # Handy bit of code for filtering digits from https://www.geeksforgeeks.org/python-extract-digits-from-given-string/
        c_dict[int(c_name[-6:])] = (max(vc), len(vc))  # Key = augmented academic year as int, Val = (max_val_in_year, major_counts)
        print(c_name + " <- c(" + c_data + ")")

    print("Number.of.Students <- c(" + ", ".join(["academic_year_" + str(k) for k in c_dict.keys()]) + ")")   # ["d" + str(i) for i in range(len(val_counts_list))]
    print("plot(Number.of.Students, xlab='Term', xaxt='n')")

    # Visual analysis suggests that the 90th percentile is a good threshold (corresponds to 65 students per major)
    quantile90 = round(np.quantile([val for sublist in val_counts_list for val in sublist], 0.9))
    quantile50 = round(np.quantile([val for sublist in val_counts_list for val in sublist], 0.5))
    print("abline(h=" + str(quantile90) + ", col='#007030')")
    print("abline(h=" + str(quantile50) + ", col='#FEE11A', lty=2)")

    # Set additional guidelines at Winter 2020, the first term impacted by COVID.
    # Partition by max before COVID
    max_val_before_covid = max([max_val_in_year if key < 201902 else 0 for (key, (max_val_in_year, major_counts)) in c_dict.items()])
    covid_x_val = sum([major_counts if key < 201902 else 0 for (key, (max_val_in_year, major_counts)) in c_dict.items()])

    print("abline(v=" + str(covid_x_val) + ", col='#CCCCCC')")
    print("abline(h=" + str(max_val_before_covid) + ", col='#FF0000', lty=3)")


    print()

    # PART 3 and 4: List the majors which produce more than 65 students on the honor roll for each year.
    # Also, find the median major for that year as a representative benchmark
    
    print("AcademicYearAugmented", "Major", "Count", "IsMedian", sep=",")
    for name, df in list_of_extracts:
        val_counts = df['MAJOR'].value_counts().to_dict()

        for key, val in val_counts.items():
            if val >= quantile90:
                print(name, key, val, False, sep=",")
            if val == quantile50:
                print(name, key, val, True, sep=",")

    # Copy results to speadsheet; Manually add department data when avaliable.

    # PART 5

    print("PART5")

    print("Year", "Major", "DeansListStudents", sep=",", file=open('majors.output.csv', 'w'))
    for name, df in list_of_extracts:
        year = int(''.join(filter(lambda i: i.isdigit(), name)))
        val_counts = df['MAJOR'].value_counts().to_dict()
        for key, val in val_counts.items():
            key = key.replace(",", "")
            if "Undeclared" in key or "Exploring" in key:
                key = "Exploring / Undeclared"
            print(year, key, val, sep=",", file=open('majors.output.csv', 'a'))

