# AlphaFold-Non-Docker

This repository provides a **non-Docker setup of AlphaFold** designed for **HPC and bare-metal environments** where Docker is unavailable or impractical.

The AlphaFold 2 installation includes patches that introduce parallelized MSA searches, configurable multithreading, and a separation of CPU- and GPU-bound stages in the AlphaFold inference pipeline.  
Please refer to the [patch notes](https://gitlab.liu.se/xuagu37/berzelius-alphafold-guide/-/blob/main/patch/patch_notes.md?ref_type=heads) for details.

---

## Tested Configurations

The following AlphaFold versions have been tested with different CUDA toolkits and GPU architectures:

| AlphaFold Version | CUDA Version | Tested GPUs |
|-------------------|--------------|-------------|
| 2.3.1             | 11.1.1       | T4, A100   |
| 2.3.2             | 11.1.1       | T4, A100   |
| 2.40be3ec       | 12.2.2       | H200       |
| 3.0.0             | 12.6.2       | T4, A100, H200 |
| 3.0.1             | 12.6.2       | T4, A100, H200 |

> **Note**  
> `40be3ec` refers to a commit hash from the AlphaFold 2 GitHub repository, as no formal release has been published after version 2.3.2.

---

## Prerequisites

You will need **one** of the following environments:

- **Miniforge3** (recommended for native Conda/Mamba-based installations)
- **Apptainer** (for containerized execution on HPC systems)

## Using Miniforge3

### Installation
Make sure you have **Miniforge3** installed.  
If you are working on an HPC system, you can uncomment the `module load` line in the installation script to load Miniforge3 via the module system.

Then, run the installation script for your desired AlphaFold version:
```bash
export AF_VERSION=2.3.1  # Set desired AlphaFold version here
export INSTALL_DIR="$HOME/AlphaFold/${AF_VERSION}"
bash conda/install_alphafold_${AF_VERSION}.sh
```

### Usage

Set up the environment variables:
```bash
source "${INSTALL_DIR}/scripts/alphafold_env.sh"
```

Activate the Mamba environment:
```bash
mamba activate ${CONDA_PREFIX}
```

Run AlphaFold with your input sequence file:
```bash
export ALPHAFOLD_DB=/proj/common-datasets/AlphaFold
export ALPHAFOLD_RESULTS=/proj/nsc_testing/xuan/alphafold_results_2.3.1
bash run_alphafold.sh \
  -d ${ALPHAFOLD_DB} \
  -o ${ALPHAFOLD_RESULTS}/output \
  -f ${ALPHAFOLD_RESULTS}/input/T1050.fasta \
  -t 2021-11-01 \
  -g false \
  -P 3 \
  -F false
```

### Flag descriptions

#### `-P` — Parallel MSA searches
Controls how many MSA search jobs are executed in parallel during the CPU preprocessing stage.

- `-P 1`  
  Run MSA searches **sequentially** (no parallelization).

- `-P 3`  
  Run MSA searches **in parallel** (UniRef90, MGnify, HHblits).  
  This significantly reduces wall-clock time on multi-core CPU nodes.

> Recommended: set `-P` to the number of MSA backends you want to run concurrently, depending on available CPU resources.

---

#### `-F` — CPU/GPU workflow separation
Controls whether the GPU-based structure prediction step is executed.

- `-F true`  
  **Only run CPU steps** (MSA generation and template search).  
  No GPU resources are required.

- `-F false`  
  Run the **full AlphaFold pipeline**, including GPU-based structure prediction.

> This option is useful when you want to precompute MSAs on CPU nodes and run GPU prediction separately.


## Using Apptainer

### Installation
Make sure you have **Apptainer** installed.

```bash
export AF_VERSION=2.3.1  # Set desired AlphaFold version here
apptainer build alphafold_${AF_VERSION}.sif apptainer/alphafold_${AF_VERSION}.def
```
### Usage

Run AlphaFold with your input sequence file:
```bash
export ALPHAFOLD_DB=/proj/common-datasets/AlphaFold
export ALPHAFOLD_RESULTS=/proj/nsc_testing/xuan/alphafold_results_2.3.1
apptainer exec --nv alphafold_${AF_VERSION}.sif \
  --bind "${ALPHAFOLD_DB}:${ALPHAFOLD_DB}" \
  --bind "${ALPHAFOLD_RESULTS}:${ALPHAFOLD_RESULTS}" \
  bash /app/alphafold/run_alphafold.sh \
  -d "${ALPHAFOLD_DB}" \
  -o "${ALPHAFOLD_RESULTS}/output" \
  -f "${ALPHAFOLD_RESULTS}/input/T1050.fasta" \
  -t 2021-11-01 \
  -g false \
  -P 3 \
  -F false
```