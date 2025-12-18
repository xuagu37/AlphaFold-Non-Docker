# AlphaFold-Non-Docker

This repository provides a **non-Docker setup of AlphaFold** designed for **HPC and bare-metal environments** where Docker is unavailable or impractical.  

The AlphaFold 2 installation includes patch which introduces parallelized MSA searches, multithreading configuration, and a separation of CPU- and GPU-bound stages in the AlphaFold inference pipeline. Please read the [patch notes](https://gitlab.liu.se/xuagu37/berzelius-alphafold-guide/-/blob/main/patch/patch_notes.md?ref_type=heads).


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

---

The `40be3ec` is a commit tag from AlphaFold 2's GitHub repository since they haven't released a formal version after 2.3.2.

## Prerequisites

You will need **one** of the following environments:

- **Miniforge3** (recommended for native Conda-based installations)
- **Apptainer** (for containerized execution on HPC systems)

## With Miniforge3

### Installation
Make sure you have Miniforge3 installed. Then, run the installation script for your desired AlphaFold version:
```bash
AF_VERSION=2.3.1  # Set desired AlphaFold version here
export INSTALL_DIR="$HOME/AlphaFold/${AF_VERSION}"
bash conda/install_alphafold_${AF_VERSION}.sh
```


### Usage



## With Apptainer