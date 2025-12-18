#!/usr/bin/env bash
set -euo pipefail
: "${INSTALL_DIR:?INSTALL_DIR must be set}"

# On HPC systems, Miniforge3 may be provided as a module.
# Uncomment the following line if needed:
# module load Miniforge3

echo "=== AlphaFold 2.3.1 installation started ==="
echo "Installation directory: ${INSTALL_DIR}"
echo

# Check that mamba is available
if ! command -v mamba >/dev/null 2>&1; then
  echo "ERROR: mamba command not found."
  echo "Please uncomment the module load line or install Miniforge3 (or another Mamba distribution) before running this script."
  exit 1
fi

TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

echo "Creating installation directory..."
mkdir -p ${INSTALL_DIR}

echo
echo "Step 1/7: Cloning installation helper repository..."
git clone --quiet https://gitlab.liu.se/xuagu37/berzelius-alphafold-guide "$TMPDIR/berzelius-alphafold-guide"

# Create conda environment
echo
echo "Step 2/7: Creating Conda environment (this may take a while)..."
mamba env create --yes --quiet \
  -f "$TMPDIR/berzelius-alphafold-guide/conda/alphafold_2.3.1.yml" \
  -p "${INSTALL_DIR}/envs/alphafold_2.3.1"

# Download AlphaFold source
echo
echo "Step 3/7: Downloading AlphaFold 2.3.1 source code..."
wget -q -O "$TMPDIR/v2.3.1.tar.gz" \
  https://github.com/deepmind/alphafold/archive/refs/tags/v2.3.1.tar.gz
tar -xf "$TMPDIR/v2.3.1.tar.gz" -C "${INSTALL_DIR}" --strip-components=1

# Apply OpenMM patch
echo
echo "Step 4/7: Applying OpenMM patch..."
cd ${INSTALL_DIR}/envs/alphafold_2.3.1/lib/python3.8/site-packages/ 
patch -p0 < ${INSTALL_DIR}/docker/openmm.patch

# Download chemical properties
echo
echo "Step 5/7: Downloading chemical properties file..."
wget -q -P "${INSTALL_DIR}/alphafold/common/" \
  https://git.scicore.unibas.ch/schwede/openstructure/-/raw/7102c63615b64735c4941278d92b554ec94415f8/modules/mol/alg/src/stereo_chemical_props.txt

# Install patch
echo
echo "Step 6/7: Installing AlphaFold patches..."
cd $TMPDIR/
bash "berzelius-alphafold-guide/patch/patch_2.3.1/patch_2.3.1.sh" "${INSTALL_DIR}"

# Final setup
echo
echo "Step 7/7: Finalizing installation..."
chmod +x ${INSTALL_DIR}/run_alphafold.sh
ln -s "${INSTALL_DIR}/run_alphafold.sh" "${INSTALL_DIR}/scripts/run_alphafold.sh"

echo
echo "=== AlphaFold 2.3.1 installation completed successfully ==="
echo "Installed in: ${INSTALL_DIR}"