#!/usr/bin/env bash
set -euo pipefail
: "${INSTALL_DIR:?INSTALL_DIR must be set}"

# On HPC systems, Miniforge3 may be provided as a module.
# Uncomment the following line if needed:
# module load Miniforge3

echo "=== AlphaFold 3.0.0 installation started ==="
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
  -f "$TMPDIR/berzelius-alphafold-guide/conda/alphafold_3.0.0.yml" \
  -p "${INSTALL_DIR}/envs/alphafold_3.0.0"

# Download AlphaFold source
echo
echo "Downloading AlphaFold 3.0.0 source code..."
wget -q -O "$TMPDIR/v3.0.0.tar.gz" \
  https://github.com/google-deepmind/alphafold3/archive/refs/tags/v3.0.0.tar.gz
tar -xf "$TMPDIR/v3.0.0.tar.gz" -C "${INSTALL_DIR}" --strip-components=1

# Install patch
echo
echo "Installing dependency..."
mamba activate "${INSTALL_DIR}/envs/alphafold_3.0.0"
pip3 install --no-deps ${INSTALL_DIR}
build_data

# Create environment setup script
echo "Creating AlphaFold environment setup script..."
cat << 'EOF' > "${INSTALL_DIR}/scripts/alphafold_env.sh"
#!/usr/bin/env bash

# AlphaFold environment setup

: "${INSTALL_DIR:?INSTALL_DIR must be set}"
: "${AF_VERSION:?AF_VERSION must be set}"

export CONDA_PREFIX="${INSTALL_DIR}/envs/alphafold_${AF_VERSION}"
export ALPHAFOLD_PREFIX="${INSTALL_DIR}"
export XLA_FLAGS="--xla_gpu_enable_triton_gemm=false"
export XLA_PYTHON_CLIENT_PREALLOCATE=True
export XLA_CLIENT_MEM_FRACTION=0.95

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
echo "=== AlphaFold 3.0.0 installation completed successfully ==="
echo "Installed in: ${INSTALL_DIR}"