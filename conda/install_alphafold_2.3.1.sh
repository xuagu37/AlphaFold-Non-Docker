#!/usr/bin/env bash

set -euo pipefail
: "${INSTALL_DIR:?INSTALL_DIR must be set}"

TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

mkdir -p ${INSTALL_DIR}

# Create conda environment
git clone https://gitlab.liu.se/xuagu37/berzelius-alphafold-guide "$TMPDIR/berzelius-alphafold-guide"
mamba env create \
  -f "$TMPDIR/berzelius-alphafold-guide/alphafold_2.3.1.yml" \
  -p "${INSTALL_DIR}/envs/alphafold_2.3.1"

# Download AlphaFold source
wget -O "$TMPDIR/v2.3.1.tar.gz" \
  https://github.com/deepmind/alphafold/archive/refs/tags/v2.3.1.tar.gz
tar -xf "$TMPDIR/v2.3.1.tar.gz" -C "${INSTALL_DIR}" --strip-components=1

# Apply OpenMM patch
cd ${INSTALL_DIR}/envs/alphafold_2.3.1/lib/python3.8/site-packages/ 
patch -p0 < ${INSTALL_DIR}/docker/openmm.patch

# Download chemical properties
wget -q -P "${INSTALL_DIR}/alphafold/common/" \
  https://git.scicore.unibas.ch/schwede/openstructure/-/raw/7102c63615b64735c4941278d92b554ec94415f8/modules/mol/alg/src/stereo_chemical_props.txt

# Install patch
bash "$TMPDIR/berzelius-alphafold-guide/patch/patch_2.3.1.sh" "${INSTALL_DIR}"

# Final setup
chmod +x ${INSTALL_DIR}/run_alphafold.sh
ln -s "${INSTALL_DIR}/run_alphafold.sh" "${INSTALL_DIR}/scripts/run_alphafold.sh"