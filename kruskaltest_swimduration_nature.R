library(tidyverse)
library(rstatix)

# choose .csv file of interest
df_1 <- read.csv(file.choose())

#filter out any animals that didn't swim for the entire movie (swim_time = 0)
df_1 <- df_1 %>% filter(swim_time > 0)

# kruskal test on swim duration
df_1 %>% kruskal_test(swim_time ~ group)

# run dunn test if kruskal wallace test shows significance; then save results to a csv
df_1 %>% filter(swim_time != 0) %>% dunn_test(swim_time ~ group) %>% write_csv("data.csv")

#setting order of the groups on the plot
my_order <- c("700nm only", "phototaxis", "unablated", "mock_ablated", "abvo_ablated")

# use factor() to reorder the levels of the "group" variable
df_1$group <- factor(df_1$group, levels = my_order)

# violin plot of the swim duration
ggplot(df_1, aes(x = group, y = swim_time, fill = group)) + geom_violin() + geom_boxplot(width = 0.1)

#save file at a higher definition
ggsave("RPlot.png", width = 8, height = 4, dpi = 300)

#summary of average and std dev; then save to a csv
df_1 %>% 
  group_by(group) %>% 
  summarise(mean = mean(swim_time), sd = sd(swim_time)) %>% write_csv("data.csv")
