# script for finding deltaF/F from Fiji output of fluorescence values
library(tidyverse)
library(broom)
library(ggpmisc)

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
      resid = augment(lm(FOverF0 ~ time, data = .x)) %>% pull(.resid)
    ),
    .keep = TRUE
  ) %>%
  bind_rows() %>%
  group_by(ROI)

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

# Gives peak values in graph. Change span and ignore_threshold to get all peaks
# labelled

span <- 15
ignore_threshold <- 0.2

ggplot(df_res, aes(x = time, y = resid, color = ROI)) +
  geom_line() +
  stat_peaks(
    colour = "red",
    span = span,
    ignore_threshold = ignore_threshold
  ) +
  stat_peaks(
    geom = "text",
    colour = "red",
    span = 15,
    ignore_threshold = 0.2,
    hjust = -0.5,
    angle = 90
  )

map2(
  df_res %>%
    group_keys() %>%
    pull(ROI),
  df_res %>%
    group_map(
      ~ ggplot_build(
        ggplot(.x, aes(x = time, y = resid)) +
          geom_line() +
          stat_peaks(span = span, ignore_threshold = ignore_threshold)
      )$data[[2]]$xintercept
    ),
  ~ tibble(ROI = .x, Interval = diff(.y), Frequency = 1 / Interval)
) %>%
  bind_rows() %>%
  group_by(ROI) %>%
  summarize(mean = mean(Frequency), sd = sd(Frequency))
