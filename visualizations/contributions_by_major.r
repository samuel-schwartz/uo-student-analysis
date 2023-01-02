dta <- read.csv("../majors.output.csv")
View(dta)

library(reshape2)
dta_wide <- dcast(dta, Major ~ Year, value.var="DeansListStudents")
dta_wide[is.na(dta_wide)] <- 0
View(dta_wide[dta_wide$`201601`>=0,])

dta_wide$`201601.To.201901.Median` <- apply(data.frame(dta_wide$`201601`, 
                                             dta_wide$`201602`, 
                                             dta_wide$`201603`, 
                                             dta_wide$`201701`, 
                                             dta_wide$`201702`, 
                                             dta_wide$`201703`, 
                                             dta_wide$`201801`, 
                                             dta_wide$`201802`, 
                                             dta_wide$`201803`, 
                                             dta_wide$`201901`), 1, median)

dta_wide$`201902.To.202103.Median` <- apply(data.frame(dta_wide$`201902`, 
                                             dta_wide$`201903`, 
                                             dta_wide$`202001`, 
                                             dta_wide$`202002`, 
                                             dta_wide$`202003`, 
                                             dta_wide$`202101`, 
                                             dta_wide$`202102`, 
                                             dta_wide$`202103`), 1, median)

dta_wide$Perc.Change.Since.Covid.Hit <- (dta_wide$`201902.To.202103.Median` - dta_wide$`201601.To.201901.Median`) / dta_wide$`201601.To.201901.Median` 

write.csv(dta_wide, "clipboard")

View(dta_wide[dta_wide$`201902.To.202103.Median` > 10 | dta_wide$`201601.To.201901.Median` > 10,])

