dta <- read.csv("../data/student_zip_census.csv")

# Create overall, WHT, and POC ratios
dta$UO_YOUTH_RATIO <- dta$UO_STUDENTS / (dta$POP_YOUTH_TOTAL + 1)
dta$UO_WHT_YOUTH_RATIO <- dta$UO_STUDENTS / (dta$WHT_YOUTH_TOTAL + 1)
dta$UO_POC_YOUTH_RATIO <- dta$UO_STUDENTS / (dta$POC_YOUTH_TOTAL + 1)

dta$WHT_YOUTH_RATIO <- dta$WHT_YOUTH_TOTAL / (dta$POP_YOUTH_TOTAL + 1)
dta$POC_YOUTH_RATIO <- dta$POC_YOUTH_TOTAL / (dta$POP_YOUTH_TOTAL + 1)

dta[is.na(dta)] <- 0
dta_large <- dta[dta$POP_YOUTH_TOTAL>0,]
plot(dta_large$POC_YOUTH_RATIO, dta_large$UO_YOUTH_RATIO)

lmout <- lm(UO_YOUTH_RATIO ~ POC_YOUTH_RATIO, data = dta)
