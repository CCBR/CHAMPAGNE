library(tidyverse)
peak_counts <- read_tsv("peak_meta.tsv") %>%
  group_by(sample_id, tool) %>%
  count() %>%
  rename(count_new = n)
peak_counts %>%
  pull(tool) %>%
  unique()

peaks_old <- read_tsv("old_peak_counts.tsv") %>%
  mutate(tool = str_remove(file, "/.*")) %>%
  mutate(
    tool = case_when(
      tool == "macsBroad" ~ "macs_broad",
      tool == "macsNarrow" ~ "macs_narrow",
      TRUE ~ tool
    ),
    sample_id = str_replace(file, ".*/(.*)/.*", "\\1"),
  ) %>%
  rename(count_old = count) %>%
  select(sample_id, tool, count_old)

inner_join(peaks_old, peak_counts) %>%
  mutate(
    rel_diff_percent = round(100 * (count_new - count_old) / count_old, 2)
  ) %>%
  View()
