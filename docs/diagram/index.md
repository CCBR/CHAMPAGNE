```mermaid
flowchart LR

%%{init: {
  "themeVariables": {
     "background": "transparent",
     "fontSize": "35px" },
  "flowchart": {
    "nodeSpacing": 80,
    "rankSpacing": 80,
    "padding": 35,
    "htmlLabels": true
}}}%%

  %% Input
  Raw["Raw Fastqs"]:::input --> Trimming["Cutadapt: Adapter removal & quality trimming"]:::process
  Trimming --> Trimmed["Trimmed Fastqs"]:::input

  %% Quality Control
  MultiQC["multiqc report"]:::output
  Trimmed --> fqscreen["FastqScreen"]:::process
  Raw --> QC_results
  Trimmed --> QC_results["FASTQC"]:::process
  QC_results --> MultiQC
  fqscreen --> MultiQC

  %% Blacklist filtering
  Trimmed --> Blacklist["Align to blacklist regions and discard reads that align"]:::process

  %% Preseq and alignment
  Blacklist --> Align["Align to reference genome, deduplicate, filter out low quality alignments"]:::process
  Align --> Cc["Preseq - library complexity curve"]:::process
  Cc ---> MultiQC

  Align --> Scc["PhantomPeakQualtools"]:::process
  Scc --> MultiQC

  %% Spike-in normalization (optional)
  Align --> Spike["Spike-in normalization (optional)"]:::process
  Spike --> InputNorm["input normalization"]:::process
  InputNorm --> NormBigwigs["Normalized Bigwigs"]:::output

  %% Deeptools steps
  Align --> Deeptools["Deeptools"]:::tool
  Deeptools --> Matrix["Compute matrix"]:::process
  Matrix --> Profile["plotProfile"]:::process
  Profile --> TSSplot["TSS plot"]:::output
  Profile --> Heatmap["Heatmap"]:::output
  TSSplot --> MultiQC
  Heatmap --> MultiQC
  Deeptools --> fingerprint["plotFingerprint"]:::process
  fingerprint --> fingerprintplot["Finger print plot"]:::output
  fingerprintplot --> MultiQC
  Deeptools --> BAMcov["BAM Coverage"]:::process
  BAMcov --> PCA["PCA plot"]:::output & Bigwig["BigWig summary"]:::output
  PCA --> MultiQC

  %% Peak calling
  NormBigwigs --> Peakcalling["Identify peaks"]:::process
  Peakcalling --> MACS2narrow["MACS2 narrow peaks"]:::tool
  Peakcalling --> GEM["GEM narrow peaks"]:::tool
  Peakcalling --> MACS2broad["MACS2 broad peaks"]:::tool
  Peakcalling --> SICER["SICER broad peaks"]:::tool
  MACS2narrow --> Consensus:::process
  GEM --> Consensus
  MACS2broad --> Consensus
  SICER --> Consensus
  Consensus --> Diffbind["Differential peak calling (DiffBind or MAnorm)"]:::process
  Consensus --> Annotate["Annotate peaks & find motifs"]:::process

  %% Styles - Modern sleek theme
  classDef input fill:#fff8e1,stroke:#d97706,stroke-width:1px;
  classDef process fill:#f1f8e9,stroke:#558b2f,stroke-width:1px;
  classDef tool fill:#e1f5fe,stroke:#01579b,stroke-width:1px;
  classDef output fill:#fdf2f8,stroke:#6a1b9a,stroke-width:1px;
```

classDef input fill: #fff8e1
classDef process fill: #f1f8e9
classDef tool fill: #e1f5fe
classDef note fill: #fff8e1
classDef output fill: #fdf2f8
