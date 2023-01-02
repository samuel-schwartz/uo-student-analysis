dta <- read.csv("../data/male_female_data_for_vis_tall.csv")
View(dta)

library(ggplot2)
library(latex2exp)

p <- ggplot(dta, aes(x = Source, y = Ratio, fill = Gender))
p <- p + theme_bw()
p <- p + geom_bar(stat = "identity")
p <- p + scale_y_continuous(labels = scales::percent)
p <- p + facet_wrap(.~AcademicYear, ncol = 2)
p <- p + coord_flip()
p <- p + theme(legend.position = "bottom")
p <- p + theme(axis.title.y = element_blank())
p <- p + theme(axis.text.x = element_text(colour = "black"))
p <- p + theme(axis.text.y = element_text(colour = "black"))
p <- p + scale_fill_manual(values=c("#007030", "#FEE11A"))
p
