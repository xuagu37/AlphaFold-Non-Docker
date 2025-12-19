#!/usr/bin/env bash

# AlphaFold environment setup

: "${INSTALL_DIR:?INSTALL_DIR must be set}"
: "${AF_VERSION:?AF_VERSION must be set}"

CONDA_PREFIX="${INSTALL_DIR}/envs/alphafold_${AF_VERSION}"

export ALPHAFOLD_PREFIX="${INSTALL_DIR}"

# Path setup
case ":$PATH:" in
  *":${INSTALL_DIR}/scripts:"*) ;;
  *) export PATH="${INSTALL_DIR}/scripts:${PATH}" ;;
esac

# Library path (only if needed)
case ":${LD_LIBRARY_PATH:-}:" in
  *":${CONDA_PREFIX}/lib:"*) ;;
  *) export LD_LIBRARY_PATH="${CONDA_PREFIX}/lib:${LD_LIBRARY_PATH:-}" ;;
esac

echo "AlphaFold ${AF_VERSION} environment configured."
