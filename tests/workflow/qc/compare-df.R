library(tidyverse)

original <- read.table("QCTable.txt", header = TRUE) %>%
  as_tibble() %>%
  mutate(across(contains("reads"), as.integer)) %>%
  select(c("SampleName", contains("reads"))) %>%
  pivot_longer(-SampleName, values_to = "value_orig")
new <- read_tsv("qc_table.tsv") %>%
  select(SampleName, original %>% pull(name)) %>%
  pivot_longer(-SampleName, values_to = "value_new")


inner_join(original, new) %>%
  mutate(rel_diff_percent = 100 * (value_new - value_orig) / value_orig) %>%
  View()
