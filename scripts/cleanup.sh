#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -euo pipefail

# --- Variables ---
CLUSTER_NAME="kagent-lab"

echo "Starting cleanup process..."

# --- 1. Delete k3d cluster ---
if k3d cluster list "${CLUSTER_NAME}" >/dev/null 2>&1; then
    echo "1. Deleting k3d cluster: ${CLUSTER_NAME}"
    k3d cluster delete "${CLUSTER_NAME}"
else
    echo "1. Cluster ${CLUSTER_NAME} does not exist. Skipping deletion."
fi

echo "Cleanup complete."
