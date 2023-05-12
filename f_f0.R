# script for finding deltaF/F from Fiji output of fluorescence values
install.packages('tidyverse')
install.packages("ggpubr")
install.packages("ggplot2")
install.packages("ggpmisc")

library("tidyverse")
library(ggpubr)
library(ggplot2)
library(ggpmisc)

#read in data.Put data from FiJi into Xcell.  Add "time" to first column heading. Save as .csv

intensity <- read_csv("larva5Results.csv")
F0values <- select(intensity, -time)
F0mean <- F0values %>%
  summarize_all(mean)
F0mean <- F0mean * 0.2
F0mean1 <- add_column(F0mean, time = 1)
FullIntensity <- full_join(intensity, F0mean1, by = "time")
FullIntensity <- fill(FullIntensity, ends_with("y")) %>% mutate(time = (time - 1) * 0.078) #put msec/frame here
#Now do math part.  Use as many lines as needed for the number of ROIs present
FOverF0 <- mutate(FullIntensity, DFOverFOne = ((Mean1.x - Mean1.y) / Mean1.y))
FOverF0 <- mutate(FOverF0, DFOverFTwo = ((Mean2.x - Mean2.y) / Mean2.y))
FOverF0 <- mutate(FOverF0, DFOverFThree = ((Mean3.x - Mean3.y) / Mean3.y))
FOverF0 <- mutate(FOverF0, DFOverFFour = ((Mean4.x - Mean4.y) / Mean4.y))
FOverF0 <- mutate(FOverF0, DFOverFFive = ((Mean5.x - Mean5.y) / Mean5.y))
FOverF0 <- mutate(FOverF0, DFOverFSix = ((Mean6.x - Mean6.y) / Mean6.y))
FOverF0 <- mutate(FOverF0, DFOverFSeven = (abs((Mean7.x - Mean7.y) / Mean7.y)))

FOverF0 <- pivot_longer(FOverF0, cols = starts_with("DFOverF"), names_to = "DeltaF")
FOverF0$DeltaF <- factor(FOverF0$DeltaF, levels = c("DFOverFOne", "DFOverFTwo", "DFOverFThree", "DFOverFFour", "DFOverFFive", "DFOverFSix", "DFOverFSeven"))

df_res <- group_by(FOverF0, DeltaF) %>% group_split() %>%
map(~ lm(value ~ time, data = .x)$residuals) %>%
as_tibble(.name_repair = "unique") %>%
  pivot_longer(everything(), names_to = "ROI", names_prefix = "...") %>%
  add_column(time = FOverF0 %>% pull(time))

df_res %>% ggplot(aes(x = time, y = value, group = ROI, color = ROI)) +
  geom_line() +
  labs(y = "DeltaF/F0", x = "time (sec)")  + theme(legend.text = element_text(size=12)) #+
  guides(colour = guide_legend(override.aes = list(size=3))) + bgcolor("#F0FFFF") +
   # xlim(25,50) #+ ylim(-0.5, 0.5)   #ylim(2, 5) #+ xlim(150,838)
  #+ bgcolor("#F0FFFF") 

df_res %>% ggplot(aes(x = time, y = value, group = ROI, color = ROI)) +
    geom_line() +
    labs(y = "DeltaF/F0", x = "time (sec)")  + theme(legend.text = element_text(size=12)) +
    guides(colour = guide_legend(override.aes = list(size=3))) +
    facet_wrap(~ROI)  #+ ylim(-1.0,1) #+ xlim(100,125) + ylim(-2, 2)
####################################################################
