#!/usr/bin/env Rscript
library(dplyr)
library(ggplot2)
library(readr)
library(scales)

set.seed(20230926)
args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 1) {
  stop(
    "Error: not enough positional arguments.\n  Example usage:\n   Rscript plot_peak_widths.R path/to/peak_widths.tsv"
  )
}
tsv_filename <- args[1]
peak_dat <- read_tsv(tsv_filename) %>%
  mutate(
    peak_width = chromEnd - chromStart,
  )
tools <- peak_dat %>%
  pull(tool) %>%
  unique()
if (length(tools) > 1) {
  peak_dat <- peak_dat %>%
    filter(tool != "gem") # exclude gem because width is always 200
}

sample_ids <- peak_dat %>%
  pull(sample_id) %>%
  unique()
fill_colors <- viridisLite::viridis(
  n = length(sample_ids),
  alpha = 0.7,
  begin = 0,
  end = 1,
  direction = 1,
  option = "D"
)
names(fill_colors) <- sample_ids

plot_hist <- function(peak_dat) {
  xmin <- peak_dat %>%
    pull(peak_width) %>%
    min()
  xmax <- peak_dat %>%
    pull(peak_width) %>%
    max()
  peak_dat %>%
    ggplot(aes(peak_width, fill = sample_id)) +
    geom_histogram(alpha = 0.7, position = "stack") +
    scale_fill_manual(
      values = fill_colors,
      breaks = names(fill_colors)
    ) +
    guides(
      fill = guide_legend(
        label.position = "bottom",
        title.position = "top"
      )
    ) +
    facet_wrap(~tool, ncol = 1) + # , scales = 'free') +
    scale_x_log10(
      breaks = scales::trans_breaks("log10", function(x) 10^x),
      labels = scales::trans_format("log10", scales::math_format(10^.x))
    ) +
    theme_bw() +
    theme(legend.position = "right")
}

hist_plot <- peak_dat %>%
  plot_hist()

ggsave(
  filename = "peak_widths_histogram.png",
  plot = hist_plot,
  device = "png",
  dpi = 300,
  height = 4,
  width = 6
)
