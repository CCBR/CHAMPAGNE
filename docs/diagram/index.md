## vertical

```mermaid

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

flowchart TB

  %% Input
  Raw["Raw Fastqs"]:::input --> Trimming["Cutadapt: Adapter removal"]:::process
  Trimming --> Trimmed["Trimmed Fastqs"]:::input
   
  %% Quality Control
   MultiQC["multiqc report"]:::output
  Trimmed --> Contaminants["FastqScreen: Potential contamination of genome from other species"]:::output
  Contaminants --> MultiQC
  Trimmed --> QC_results["FASTQC: Data quality and presence of adapter read through"]:::output
  QC_results --> MultiQC

  %% Blacklist filtering
  Trimmed --> Blacklist["Align to blacklist regions and discard reads that align"]:::process

  %% Preseq and alignment
  Blacklist --> Align["Align to reference genome, deduplicate, filter out low quality alignments"]:::process
  Align --> Cc["Preseq: Estimates and plots library complexity curve"]:::output
  Cc ---> MultiQC

  %% Phantompeakqualtools and alignment
  Align --> Scc["Phanetompeakqualtools: Calculates and plots strand correlation"]:::output
  Scc --> MultiQC

  %% Spike-in normalization (optional)
  Align --> Spike["optional: spike-in normalization"]:::note
  Spike --> InputNorm["input normalization"]:::note
  InputNorm --> NormBigwigs["Normalized Bigwigs"]:::output

  %% Deeptools steps
  Align --> Deeptools["Deeptools"]:::tool
  Deeptools --> Matrix["Compute matrix"]:::process
  Matrix --> Profile["Deeptools: plotProfile"]:::process
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
  NormBigwigs --> MACS2narrow["MACS2 narrow"]:::tool
  NormBigwigs --> MACS2broad["MACS2 broad"]:::tool
  NormBigwigs --> SICER["SICER"]:::tool
  NormBigwigs --> GEM["GEM"]:::tool
  MACS2narrow --> Consensus["consensus peak calling"]:::process
  MACS2broad --> Consensus
  GEM --> Consensus
  SICER --> Consensus
  Consensus --> Diffbind["Differential peak calling using DiffBind or MAnorm"]:::process
  Consensus --> Annotate["Annotate peaks, find motifs"]:::process

  %% Styles
  classDef input fill:#fdecea,stroke:#e57373,stroke-width:1px;
  classDef process fill:#e8f5e9,stroke:#81c784,stroke-width:1px;
  classDef tool fill:#e3f2fd,stroke:#64b5f6,stroke-width:1px;
  classDef note fill:#fffde7,stroke:#fbc02d,stroke-width:1px,font-style:italic;
  classDef output fill:#ede7f6,stroke:#9575cd,stroke-width:1px;
  classDef data fill:#f3e5f5,stroke:#ba68c8,stroke-width:1px;
```

## horizontal

```mermaid
flowchart LR

%% Input
Raw["Raw Fastqs"]:::input -->|Adapter trimming| Trimmed["Trimmed Fastqs"]:::input
Raw -.-> QCnote["QC with PPQT, Deeptools, Preseq, FASTQC, FastqScreen"]:::note
Trimmed --> Cutadapt["cutadapt"]:::process
Cutadapt --> Trimmed


%% Quality Control
Trimmed --> QC["Quality check"]:::process
QC --> FastqScreen["FastqScreen"]:::tool
QC --> FASTQC["FASTQC"]:::tool
QC --> Phantom["Phantompeakqualtools"]:::tool
QC --> Deeptools["Deeptools"]:::tool


%% Blacklist filtering
Trimmed --> Blacklist["Align to blacklist regions and discard reads that align"]:::process


%% Preseq and alignment
Preseq["Preseq"]:::tool --> Align["Align to reference genome, deduplicate, filter out low quality alignments"]:::process
Blacklist --> Align


%% Spike-in normalization (optional)
Align --> Spike["optional: spike-in normalization"]:::note
Spike --> InputNorm["input normalization"]:::note
InputNorm --> NormBigwigs["Normalized Bigwigs"]:::data


%% Deeptools steps
Align --> Deeptools2["Deeptools"]:::tool
Deeptools2 --> Matrix["Compute matrix"]:::process
Deeptools2 --> BAMcov["BAM Coverage"]:::process
Deeptools2 --> Fingerprint["fingerprintPlot"]:::process


Matrix --> Heatmap["TSS profile plot and heatmap"]:::output
BAMcov --> Bigwig["BigWig summary"]:::process
Bigwig --> PCA["PCA plot"]:::output
Heatmap --> Correlation["Plot sample correlation"]:::output


%% Peak calling
NormBigwigs --> MACS2narrow["macs2 narrow"]:::tool
NormBigwigs --> MACS2broad["macs2 broad"]:::tool
NormBigwigs --> SICER["sicer"]:::tool
MACS2narrow --> Consensus["consensus peak calling"]:::process
MACS2broad --> Consensus
SICER --> Consensus
Consensus --> Diffbind["Differential peak calling using DiffBind or MAnorm"]:::process
Consensus --> Annotate["Annotate peaks, find motifs"]:::process
%Annotate --> MultiQC["multiqc report"]:::output
%Diffbind --> MultiQC


%% Styles
classDef input fill:#fdecea,stroke:#e57373,stroke-width:1px;
classDef process fill:#e8f5e9,stroke:#81c784,stroke-width:1px;
classDef tool fill:#e3f2fd,stroke:#64b5f6,stroke-width:1px;
classDef note fill:#fffde7,stroke:#fbc02d,stroke-width:1px,font-style:italic;
classDef output fill:#ede7f6,stroke:#9575cd,stroke-width:1px;
classDef data fill:#f3e5f5,stroke:#ba68c8,stroke-width:1px;
```
