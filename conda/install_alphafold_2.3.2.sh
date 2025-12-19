#!/usr/bin/env bash
set -euo pipefail
: "${INSTALL_DIR:?INSTALL_DIR must be set}"

# On HPC systems, Miniforge3 may be provided as a module.
# Uncomment the following line if needed:
# module load Miniforge3

echo "=== AlphaFold 2.3.2 installation started ==="
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
echo "Cloning installation helper repository..."
git clone --quiet https://gitlab.liu.se/xuagu37/berzelius-alphafold-guide "$TMPDIR/berzelius-alphafold-guide"

# Create mamba environment
echo
echo "Creating Mamba environment (this may take a while)..."
mamba env create --yes --quiet \
  -f "$TMPDIR/berzelius-alphafold-guide/conda/alphafold_2.3.2.yml" \
  -p "${INSTALL_DIR}/envs/alphafold_2.3.2"

# Download AlphaFold source
echo
echo "Downloading AlphaFold 2.3.2 source code..."
wget -q -O "$TMPDIR/v2.3.2.tar.gz" \
  https://github.com/deepmind/alphafold/archive/refs/tags/v2.3.2.tar.gz
tar -xf "$TMPDIR/v2.3.2.tar.gz" -C "${INSTALL_DIR}" --strip-components=1

# Apply OpenMM patch
echo
echo "Applying OpenMM patch..."
cd ${INSTALL_DIR}/envs/alphafold_2.3.2/lib/python3.8/site-packages/ 
patch -p0 < ${INSTALL_DIR}/docker/openmm.patch

# Download chemical properties
echo
echo "Downloading chemical properties file..."
wget -q -P "${INSTALL_DIR}/alphafold/common/" \
  https://git.scicore.unibas.ch/schwede/openstructure/-/raw/7102c63615b64735c4941278d92b554ec94415f8/modules/mol/alg/src/stereo_chemical_props.txt

# Install patch
echo
echo "Installing AlphaFold patches..."
cd $TMPDIR/
bash "berzelius-alphafold-guide/patch/patch_2.3.2/patch_2.3.2.sh" "${INSTALL_DIR}"

# Create environment setup script
echo "Creating AlphaFold environment setup script..."
cat << 'EOF' > "${INSTALL_DIR}/scripts/alphafold_env.sh"
#!/usr/bin/env bash

# AlphaFold environment setup

: "${INSTALL_DIR:?INSTALL_DIR must be set}"
: "${AF_VERSION:?AF_VERSION must be set}"

export CONDA_PREFIX="${INSTALL_DIR}/envs/alphafold_${AF_VERSION}"
export ALPHAFOLD_PREFIX="${INSTALL_DIR}"

# Path setup
case ":$PATH:" in
  *":${INSTALL_DIR}/scripts:"*) ;;
  *) export PATH="${INSTALL_DIR}/scripts:$PATH" ;;
esac

# Library path (only if needed)
case ":${LD_LIBRARY_PATH:-}:" in
  *":${CONDA_PREFIX}/lib:"*) ;;
  *) export LD_LIBRARY_PATH="${CONDA_PREFIX}/lib:${LD_LIBRARY_PATH:-}" ;;
esac

echo "AlphaFold ${AF_VERSION} environment configured."
EOF

chmod +x "${INSTALL_DIR}/scripts/alphafold_env.sh"


# Final setup
echo
echo "Finalizing installation..."
chmod +x ${INSTALL_DIR}/run_alphafold.sh
ln -sf "${INSTALL_DIR}/run_alphafold.sh" "${INSTALL_DIR}/scripts/run_alphafold.sh"

echo
echo "=== AlphaFold 2.3.2 installation completed successfully ==="
echo "Installed in: ${INSTALL_DIR}"