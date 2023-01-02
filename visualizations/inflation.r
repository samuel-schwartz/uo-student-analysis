dta <- read.csv("../data/inflation_data_for_vis.csv")
dta$Percentage <- as.numeric(dta$Count) / as.numeric(dta$Enrollment)
dta$Term <- factor(dta$Term, levels = c("Fall", "Winter", "Spring"))
View(dta)

library(ggplot2)
library(latex2exp)

p <- ggplot(dta, aes(AcademicYear, Percentage))
p <- p + theme_bw()
p <- p + geom_point(aes(shape=Term))
p <- p + stat_smooth(aes(AcademicYearAugmented/100 - 2011, Percentage), se=F, color="#007030")
p <- p + geom_point(aes(shape=Term))
p <- p + theme(axis.text.x = element_text(angle = 45, hjust=1))
p <- p + theme(axis.text.x = element_text(colour = "black"))
p <- p + theme(axis.text.y = element_text(colour = "black"))
p <- p + scale_y_continuous(labels = scales::percent)
p <- p + ggtitle(TeX("Percentage of students with term GPAs $\\geq$ 3.75"))
p
