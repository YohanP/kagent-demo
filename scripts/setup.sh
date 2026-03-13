#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -euo pipefail

# --- Variables ---
CLUSTER_NAME="kagent-lab"
ARGOCD_NAMESPACE="argocd"
K3D_PORT_MAPPING="8080:80@loadbalancer"
ARGOCD_INSTALL_YAML="https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"
ARGOCD_SERVER_DEPLOYMENT="argocd-server"
ARGOCD_TIMEOUT="600s"

echo "Starting local environment setup..."

# --- 1. Create a k3d cluster ---
if k3d cluster list "${CLUSTER_NAME}" >/dev/null 2>&1; then
  echo "1. Cluster ${CLUSTER_NAME} already exists. Skipping creation."
else
  echo "1. Creating k3d cluster: ${CLUSTER_NAME} with port mapping ${K3D_PORT_MAPPING}"
  k3d cluster create "${CLUSTER_NAME}" --port "${K3D_PORT_MAPPING}"
fi

# --- 2. Install ArgoCD in the argocd namespace ---
echo "2. Creating Kubernetes namespace: ${ARGOCD_NAMESPACE}"
kubectl create namespace "${ARGOCD_NAMESPACE}" || true # Continue if namespace already exists

# --- Configuring ArgoCD for Insecure mode ---
echo "3. Configuring ArgoCD for Insecure mode (HTTP internal)..."
kubectl apply -k infrastructure -n "${ARGOCD_NAMESPACE}" --server-side

# --- 4. Wait for the ArgoCD API server to be ready ---
echo "4. Waiting for ArgoCD API server deployment/${ARGOCD_SERVER_DEPLOYMENT} in namespace ${ARGOCD_NAMESPACE} to be ready (timeout: ${ARGOCD_TIMEOUT})..."
kubectl wait --for=condition=Available deployment/"${ARGOCD_SERVER_DEPLOYMENT}" -n "${ARGOCD_NAMESPACE}" --timeout="${ARGOCD_TIMEOUT}"

echo "ArgoCD API server is ready."

# --- 5. Output the initial admin password for ArgoCD ---
echo "5. Retrieving initial ArgoCD admin password..."
ADMIN_PASSWORD=$(kubectl -n "${ARGOCD_NAMESPACE}" get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

if [ -z "${ADMIN_PASSWORD}" ]; then
  echo "Error: Could not retrieve ArgoCD initial admin password."
else
  echo "---------------------------------------------------"
  echo "ArgoCD UI is available at: http://localhost:8080"
  echo "Username: admin"
  echo "Password: ${ADMIN_PASSWORD}"
  echo "---------------------------------------------------"
fi

# --- 6. Create ArgoCD Ingress ---
echo "6. Applying ArgoCD Ingress from infrastructure/argocd-ingress.yaml"
kubectl apply -n "${ARGOCD_NAMESPACE}" -f infrastructure/argocd-ingress.yaml

# --- 7. Create ArgoCD ApplicationSet ---
echo "6. Applying ArgoCD ApplicationSet from argocd/applicationset.yaml"
kubectl apply -n "${ARGOCD_NAMESPACE}" -f argocd/applicationset.yaml

echo "Local environment setup complete."
