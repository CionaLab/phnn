# script for finding deltaF/F from Fiji output of fluorescence values
library(tidyverse)
library(broom)

# Put exposure time in sec here
t_exposure <- 0.107

# Read in data. this data is a .csv file from Fiji.  Use ROI manager to pick
# ROIs and "multi measure" to get file.

intensity <- read_csv(file.choose()) %>%
  rename(time = "...1") %>%
  pivot_longer(
    cols = starts_with("Area") |
      starts_with("Min") |
      starts_with("Max") |
      starts_with("Mean"),
    names_to = c("Type", "ROI"),
    names_pattern = "(\\w+)(\\d)+"
  ) %>%
  pivot_wider(names_from = "Type", values_from = "value") %>%
  mutate(time = (time - 1) * t_exposure)

f_over_f0 <- intensity %>%
  mutate(ROI = as_factor(ROI)) %>%
  group_by(ROI) %>%
  group_map(
    ~ mutate(
      .x,
      F0 = mean(Mean) * 0.2,
      FOverF0 = (Mean - F0) / F0
    ),
    .keep = TRUE
  ) %>%
  bind_rows()

df_res <- f_over_f0 %>%
  group_by(ROI) %>%
  group_map(
    ~ mutate(
      .x,
      resid = augment(lm(f_over_f0 ~ time, data = .x)) %>% pull(.resid)
    ),
    .keep = TRUE
  ) %>%
  bind_rows()

ggplot(df_res, aes(x = time, y = resid, group = ROI, color = ROI)) +
  geom_line() +
  theme_minimal() +
  labs(y = "DeltaF/F0", x = "time (sec)") +
  theme(
    legend.text = element_text(size = 12),
    axis.text = element_text(size = 20, face = "bold"),
    axis.title = element_text(size = 20, face = "bold")
  )

ggplot(df_res, aes(x = time, y = resid, group = ROI, color = ROI)) +
  geom_line() +
  theme_minimal() +
  labs(y = "DeltaF/F0", x = "time (sec)") +
  guides(colour = guide_legend(override.aes = list(size = 3))) +
  theme(
    legend.text = element_text(size = 12),
    axis.text = element_text(size = 20, face = "bold"),
    axis.title = element_text(size = 20, face = "bold")
  ) +
  facet_wrap(~ROI, ncol = 1)
