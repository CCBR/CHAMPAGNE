# Running CHAMPAGNE on Windows (WSL)

CHAMPAGNE is a Nextflow pipeline and its tasks run as Linux shell scripts, so it
does **not** run natively on Windows. The supported way to use it on a Windows
machine is inside the **Windows Subsystem for Linux (WSL2)**. This guide walks a
new user through a reproducible setup from scratch.

The end result is a single conda environment (defined by
[`environment.yml`](https://github.com/CCBR/CHAMPAGNE/blob/main/environment.yml))
that contains everything the host needs: GNU coreutils, Nextflow 25.10, Apptainer
(for real containerized runs), and the `champagne` CLI.

!!! note

    Everything from step 3 onward happens **inside** the Ubuntu (WSL) terminal,
    not PowerShell.

## 1. Install WSL2 and Ubuntu

Open **PowerShell as Administrator** and run:

```powershell
wsl --install -d Ubuntu
```

Reboot if prompted, then launch **Ubuntu** from the Start menu and create your
Linux username and password when asked. Confirm you are on WSL2:

```powershell
wsl --status
```

## 2. Configure Git line endings (Windows side)

The pipeline's scripts must keep Unix (`LF`) line endings; a `CRLF` checkout
corrupts shebangs and shell scripts under Linux (you would see errors like
`env: 'python3\r': No such file or directory`). The repo's `.gitattributes`
already enforces `LF`, but make sure Git does not rewrite endings on Windows:

```powershell
git config --global core.autocrlf false
```

If you edit the code in Cursor/VS Code, also set the default end-of-line to `\n`
in your **user** `settings.json`:

```json
"files.eol": "\n"
```

## 3. Install conda (Miniforge) inside WSL

In the **Ubuntu** terminal:

```sh
wget "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh"
bash Miniforge3-Linux-x86_64.sh -b -p "$HOME/miniforge3"
"$HOME/miniforge3/bin/conda" init bash
exec bash   # reload the shell so `conda` is available
```

## 4. Clone the repo into the WSL filesystem

!!! warning "Clone into your Linux home, not `/mnt/c` or `/mnt/d`"

    Working from a Windows-mounted drive (`/mnt/...`) under WSL is slow and can
    cause permission and line-ending problems. Clone into the native Linux
    filesystem (e.g. `~/`) instead.

```sh
cd ~
git clone https://github.com/CCBR/CHAMPAGNE
cd CHAMPAGNE
```

## 5. Create the environment

From the repo root:

```sh
conda env create -f environment.yml
conda activate champagne
```

This installs GNU coreutils (see the note below), Nextflow in the 25.10 line,
and the `champagne` CLI. Verify the toolchain:

```sh
champagne --version
nextflow -version         # should report 25.10.x
date +%s%3N               # should print 13 digits (e.g. 1784309641004)
```

!!! note "Why GNU coreutils is in the environment"

    Ubuntu 25.10+ ships **uutils coreutils** (a Rust rewrite) as the default
    `date`, whose `%3N` output breaks Nextflow's task wrapper and produces
    `.command.run: line NNN: Unexpected: unbound variable`. The `champagne`
    environment installs GNU coreutils so `date` behaves as Nextflow expects.

## 6. Containers (for real runs)

Stub runs (below) do not need containers. **Real** runs execute each tool inside
a container, so you need a container runtime in WSL:

- **Apptainer (recommended here):** it is already bundled in the `champagne`
  conda environment from step 5, so there is nothing extra to install. It runs
  rootless (no daemon, no Docker Desktop) using WSL2 user namespaces. Run the
  pipeline with `-profile apptainer`. If you built your env before Apptainer was
  added, refresh it with `conda env update -f environment.yml --prune`.
- **Docker Desktop (alternative):** install
  [Docker Desktop](https://www.docker.com/products/docker-desktop/), then enable
  **Settings → Resources → WSL Integration** for your Ubuntu distro. Run the
  pipeline with `-profile docker`. Note that Docker Desktop requires a paid
  license for larger organizations.

Verify Apptainer works:

```sh
apptainer exec docker://alpine:3.19 echo ok
```

Before a real run, point the image cache **and** Apptainer's *build* temp at a
**Linux-filesystem** path (not `/mnt/d/...` — NTFS is slow; and not `/tmp` —
on WSL `/tmp` is often a small RAM-backed `tmpfs` that fills during large
image conversions with `no space left on device`). Add this to your
`~/.bashrc` or run it each session:

```sh
export NXF_SINGULARITY_CACHEDIR="$HOME/.apptainer/cache"
export APPTAINER_TMPDIR="$HOME/.apptainer/tmp"
export SINGULARITY_TMPDIR="$APPTAINER_TMPDIR"
mkdir -p "$NXF_SINGULARITY_CACHEDIR" "$APPTAINER_TMPDIR"
```

Do **not** `export TMPDIR=...` for this. Nextflow forwards `TMPDIR` into every
task container as `SINGULARITYENV_TMPDIR`, which makes Apptainer fail with
`Unknown problem creating directory` / exit 141 on otherwise healthy tasks.

## 7. Smoke test with a stub run

A stub run exercises the whole workflow graph without doing real computation or
needing containers. Use a **self-contained** test config — the same ones CI runs
off Biowulf.

!!! note "For a container-free stub, use the configs below (not `-profile test`)"

    `-profile test` is self-contained and runs off Biowulf **when combined with a
    container profile** (see [step 8](#8-running-for-real-no-stub)). It is not
    ideal for a *container-free* stub, though: it defines contrasts, and the
    contrast-check step runs a real R script (there is no stub for it), so without
    a container it fails with `env: 'Rscript': No such file`. The configs below
    have no such step and stub cleanly on the host.

From the repo root, run the reference download-and-build stub (self-contained;
`run_qc` is off so it needs no external databases):

```sh
champagne run -stub -c tests/nxf/ci_stub_download.config \
  --max_cpus 2 --max_memory 6.GB --mode local
```

To run the general stub (mirrors CI exactly — note it uses paths relative to
`tests/nxf`, so run it from there after `champagne init`):

```sh
cd tests/nxf
champagne init
champagne run -stub -c ci_stub.config --max_cpus 2 --max_memory 6.GB --mode local
```

If either completes, your setup is working.

## 8. Running for real (no stub)

A real run drops `-stub` and adds a container profile (`-profile apptainer` from
step 6). FastQ Screen skips itself automatically when its databases are not
configured (the Biowulf-only paths), so you do not need `--run_qc false`.

**First, validate a real containerized run on the tiny built-in test data** (fast,
low memory — this actually builds a small genome and runs the tools in
containers):

```sh
# once per shell (or put in ~/.bashrc) — do NOT export TMPDIR (see step 6)
export NXF_SINGULARITY_CACHEDIR="$HOME/.apptainer/cache"
export APPTAINER_TMPDIR="$HOME/.apptainer/tmp"
export SINGULARITY_TMPDIR="$APPTAINER_TMPDIR"
mkdir -p "$NXF_SINGULARITY_CACHEDIR" "$APPTAINER_TMPDIR"

cd tests/nxf
champagne init
champagne run -profile apptainer -c ci_test.config \
  --max_cpus 2 --max_memory 6.GB --mode local
```

The first real run pulls several container images from Docker Hub (can take
10–30 minutes and a few GB of disk). Later runs reuse
`$NXF_SINGULARITY_CACHEDIR`.

**Then, run your own data on hg38.** With `index_dir` unset (the default), the
pipeline downloads the UCSC FASTA and GENCODE GTF and builds the hg38 reference
on first use. Point `--genome_cache_dir` at persistent Linux storage so the
build is reused on later runs instead of rebuilt:

```sh
champagne run -profile apptainer \
  --input /path/to/your_samplesheet.csv \
  --genome hg38 \
  --genome_cache_dir "$HOME/.cache/champagne/refs" \
  --max_cpus 4 --max_memory 12.GB --mode local
```

!!! warning "hg38 builds are heavy"

    Building the full hg38 BWA index needs substantial RAM and disk and can take
    a while on a laptop. Thanks to `--genome_cache_dir` you only pay that cost
    once. If you already have prebuilt references, point `--index_dir` at them to
    skip the download/build entirely.

## Troubleshooting (WSL-specific)

| Symptom | Cause | Fix |
|---|---|---|
| `.command.run: line NNN: Unexpected: unbound variable` | uutils `date` on Ubuntu 25.10+ | Use the `champagne` conda env (installs GNU coreutils) |
| `` `outputDir` is not defined `` / config parse errors | Nextflow 26.x strict parser | Use Nextflow 25.10 (in the env), or `export NXF_VER=25.10.0` |
| `env: 'python3\r': No such file or directory` | `CRLF` line endings | See [step 2](#2-configure-git-line-endings-windows-side); re-clone or run `git add --renormalize .` |
| `Process requirement exceeds available memory -- req: 120 GB` | request not capped to your RAM | Pass `--max_memory` (e.g. `6.GB`) and ensure you're on Nextflow 25.10 so `resourceLimits` caps requests |
| `env: 'Rscript': No such file` during a stub run | stubbed `-profile test` on the host; the contrast-check step runs real R | Run stubs with a self-contained config (see [step 7](#7-smoke-test-with-a-stub-run)), or add a container profile for a real run |
| `unauthorized` pulling `quay.io/nciccbr/...` | Singularity defaulted bare image names to quay.io; CCBR images live on Docker Hub | Use `-profile apptainer` (sets `singularity.registry = 'docker.io'`). Pull a test image with `apptainer pull docker://docker.io/nciccbr/ccbr_ubuntu_base_20.04:v6.1` |
| `no space left on device` while packing a SIF under `/tmp/build-temp-...` | WSL `/tmp` is a small RAM `tmpfs` (~8 GB); large images overflow it | Set `APPTAINER_TMPDIR`/`SINGULARITY_TMPDIR` to a disk path (see [step 6](#6-containers-for-real-runs)); `rm -rf /tmp/build-temp-*` then retry |
| `Unknown problem creating directory` / exit 141 on a task | `TMPDIR` was exported on the host and leaked into containers | `unset TMPDIR` and remove it from `~/.bashrc`; keep only `APPTAINER_TMPDIR` / `SINGULARITY_TMPDIR` / `NXF_SINGULARITY_CACHEDIR` |
| `tree: command not found` / spooker traceback after a run | `ccbr_tools` spooker needs the `tree` CLI | `conda install -n champagne -c conda-forge tree` (already in `environment.yml`) |

See also the general [Troubleshooting](troubleshooting.md) page and
[running the Nextflow pipeline directly](../nextflow.md).
