#!/usr/bin/env Rscript
library(dplyr)
library(ggplot2)
library(readr)
library(tidyr)

set.seed(20230922)
args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 1) {
  stop("Error: not enough positional arguments.\n  Example usage:\n   Rscript plot_frip.R path/to/frips.txt")
}

frip_filename <- args[1]
frip_dat <- read_tsv(frip_filename) %>%
  mutate(peak_type = case_when(
    bedtool == "sicer" | bedtool == "macs_broad" ~ "broad",
    bedtool == "gem" | bedtool == "macs_narrow" ~ "narrow",
    TRUE ~ NA_character_
  ))

sample_frip_plot <- frip_dat %>%
  mutate(n_overlap_reads_mil = n_overlap_reads / 10^6) %>%
  rename(
    `Fraction of Reads in Peaks` = FRiP,
    `Number of Reads in Peaks (millions)` = n_overlap_reads_mil
  ) %>%
  pivot_longer(c(`Fraction of Reads in Peaks`, `Number of Reads in Peaks (millions)`),
    names_to = "metric"
  ) %>%
  ggplot(aes(value, bedsample, color = bedtool)) +
  facet_wrap(peak_type ~ metric, scales = "free_x", strip.position = "bottom") +
  geom_jitter(alpha = 0.8, height = 0.1) +
  geom_hline(
    yintercept = seq(1.5, max(length(unique(frip_dat %>% pull(bedsample))) - 0.5, 1.5), 1),
    lwd = 0.5, color = "grey92"
  ) +
  guides(color = guide_legend(
    label.position = "bottom",
    title = "Peak caller",
    title.position = "top"
  )) +
  labs(x = "", y = "") +
  theme_bw() +
  theme(
    panel.grid.major.y = element_blank(),
    strip.placement = "outside",
    strip.background = element_blank(),
    legend.position = "top"
  )
ggsave(filename = "FRiP_samples.png", plot = sample_frip_plot, device = "png", dpi = 300, height = 4.5, width = 6.5)

nbasesM_frip_plot <- frip_dat %>%
  ggplot(aes(n_basesM, FRiP, color = bedsample, shape = bedtool)) +
  geom_point(alpha = 0.8) +
  facet_wrap(~peak_type, scales = "free") +
  guides(
    color = guide_legend(title = "Sample"),
    shape = guide_legend(title = "Peak caller")
  ) +
  labs(x = "Number of Bases (millions) in Peaks", y = "Fraction of Reads in Peaks") +
  theme_bw()
ggsave(filename = "FRiP_nbasesM.png", plot = nbasesM_frip_plot, device = "png", dpi = 300, height = 4, width = 6)
