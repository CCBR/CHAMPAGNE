#!/usr/bin/env Rscript

library(broom)
library(dplyr)
library(ggplot2)
library(glue)
library(purrr)
library(readr)
library(tidyr)

plot_jaccard_pca <- function(dat) {
  dat_wide <- dat %>%
    select(tool_label_A, tool_label_B, jaccard) %>%
    pivot_wider(names_from = tool_label_A, values_from = jaccard) %>%
    mutate(across(where(is.numeric), ~ replace_na(., 1)))
  pca <- dat_wide %>%
    select(-tool_label_B) %>%
    prcomp(scale = TRUE)
  pct_var <- pca %>%
    tidy(matrix = "eigenvalues") %>%
    mutate(percent = round(percent * 100, 1))
  pca_plot <- pca %>%
    augment(dat_wide) %>%
    separate(col = tool_label_B, into = c("tool", "label"), sep = " \\| ") %>%
    ggplot(aes(.fittedPC1, .fittedPC2, color = label, shape = tool)) +
    geom_point(size = 2.5, alpha = 0.8) +
    labs(
      x = glue("PC1 ({pct_var %>% filter(PC==1) %>% pull(percent)}%)"),
      y = glue("PC2 ({pct_var %>% filter(PC==2) %>% pull(percent)}%)")
    ) +
    theme_bw()
  return(pca_plot)
}

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 1) {
  stop(
    "Error: not enough positional arguments.\n  Example usage:\n   Rscript plot_jaccard.R path/to/jaccard.txt"
  )
}
jaccard_tsv <- args[1]
jaccard_dat <- read_tsv(jaccard_tsv) %>%
  mutate(
    tool_label_A = glue("{toolA} | {labelA}"),
    tool_label_B = glue("{toolB} | {labelB}")
  )

# heatmap on all tools & samples
jaccard_heatmap <- jaccard_dat %>%
  ggplot(aes(x = tool_label_A, y = tool_label_B, fill = jaccard)) +
  geom_tile() +
  scale_fill_viridis_c() +
  theme_classic() +
  theme(
    axis.text.x = element_text(angle = 90),
    axis.title.x = element_blank(),
    axis.title.y = element_blank()
  )
ggsave(
  plot = jaccard_heatmap,
  filename = "jaccard_heatmap_all.png",
  device = "png",
  dpi = 300,
  height = 6,
  width = 7
)

# one PCA with all tools & samples
jaccard_dat %>%
  plot_jaccard_pca() %>%
  ggsave(
    plot = .,
    filename = "jaccard_pca_all.png",
    device = "png",
    dpi = 300,
    height = 4,
    width = 6
  )

# plot PCA per peak-calling tool
peak_callers <- c(
  jaccard_dat %>% pull(toolA),
  jaccard_dat %>% pull(toolB)
) %>%
  unique()
dat_pca <- peak_callers %>%
  map(function(tool) {
    dat_wide <- jaccard_dat %>%
      filter(toolA == tool & toolB == tool) %>%
      select(labelA, labelB, jaccard) %>%
      pivot_wider(names_from = labelA, values_from = jaccard) %>%
      mutate(across(where(is.numeric), ~ replace_na(., 1)))
    if (nrow(dat_wide) == 0) {
      pca_tidy <- data.frame()
    } else {
      pca_tidy <- dat_wide %>%
        select(-labelB) %>%
        prcomp(scale = TRUE) %>%
        augment(dat_wide) %>%
        mutate(tool = tool) %>%
        rename(label = labelB)
    }
    return(pca_tidy)
  }) %>%
  list_rbind()
if (nrow(dat_pca) > 0) {
  pca_per_tool <- dat_pca %>%
    ggplot(aes(.fittedPC1, .fittedPC2, color = label, shape = tool)) +
    geom_point(size = 2.5, alpha = 0.8) +
    facet_wrap("tool") +
    labs(x = "PC1", y = "PC2") +
    theme_bw()
  ggsave(
    plot = pca_per_tool,
    filename = "jaccard_pca_tool.png",
    device = "png",
    dpi = 300,
    height = 4,
    width = 7
  )
}
