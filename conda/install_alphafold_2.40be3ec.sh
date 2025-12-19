#!/usr/bin/env bash
set -euo pipefail
: "${INSTALL_DIR:?INSTALL_DIR must be set}"

# On HPC systems, Miniforge3 may be provided as a module.
# Uncomment the following line if needed:
# module load Miniforge3

echo "=== AlphaFold 2.40be3ec installation started ==="
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
echo "Step 1: Cloning installation helper repository..."
git clone --quiet https://gitlab.liu.se/xuagu37/berzelius-alphafold-guide "$TMPDIR/berzelius-alphafold-guide"

# Create mamba environment
echo
echo "Step 2: Creating Mamba environment (this may take a while)..."
mamba env create --yes --quiet \
  -f "$TMPDIR/berzelius-alphafold-guide/conda/alphafold_2.40be3ec.yml" \
  -p "${INSTALL_DIR}/envs/alphafold_2.40be3ec"

# Download AlphaFold source
echo
echo "Step 3: Downloading AlphaFold 2.40be3ec source code..."
git clone https://github.com/google-deepmind/alphafold "$TMPDIR/alphafold"
cd "$TMPDIR/alphafold"
git checkout 40be3ec
# Copy EVERYTHING, including dotfiles
cp -a . "${INSTALL_DIR}/"
# jax 0.4.26 does not have scipy.special.softmax
# To fix this:
sed -i 's/from jax\.scipy import special/from scipy import special/' \
    ${INSTALL_DIR}/alphafold/common/confidence.py

# Download chemical properties
echo
echo "Step 5: Downloading chemical properties file..."
wget -q -P "${INSTALL_DIR}/alphafold/common/" \
  https://git.scicore.unibas.ch/schwede/openstructure/-/raw/7102c63615b64735c4941278d92b554ec94415f8/modules/mol/alg/src/stereo_chemical_props.txt

# Install patch
echo
echo "Step 6: Installing AlphaFold patches..."
cd $TMPDIR/
bash "berzelius-alphafold-guide/patch/patch_2.40be3ec/patch_2.40be3ec.sh" "${INSTALL_DIR}"

# Create environment setup script
echo "Step 8 Creating AlphaFold environment setup script..."
cat << 'EOF' > "${INSTALL_DIR}/scripts/alphafold_env.sh"
#!/usr/bin/env bash

# AlphaFold environment setup

: "${INSTALL_DIR:?INSTALL_DIR must be set}"
: "${AF_VERSION:?AF_VERSION must be set}"

CONDA_PREFIX="${INSTALL_DIR}/envs/alphafold_${AF_VERSION}"

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
echo "Step 7/7: Finalizing installation..."
chmod +x ${INSTALL_DIR}/run_alphafold.sh
ln -sf "${INSTALL_DIR}/run_alphafold.sh" "${INSTALL_DIR}/scripts/run_alphafold.sh"

echo
echo "=== AlphaFold 2.40be3ec installation completed successfully ==="
echo "Installed in: ${INSTALL_DIR}"