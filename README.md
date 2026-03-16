# kagent AI-Driven GitOps Demo

This repository demonstrates a modern **Self-Healing Infrastructure** workflow using the [kagent](https://kagent.dev) AI agent. It showcases how an AI agent can bridge the gap between runtime failures in a Kubernetes cluster and the GitOps source of truth.

The demo environment simulates the daily operations of a Platform Engineer or SRE, emphasizing automated problem detection and remediation via Pull Requests.

---

## Project Architecture

The setup involves a complete local GitOps stack:
- **Local Cluster**: Managed by `k3d`.
- **GitOps Engine**: `ArgoCD` managing the application lifecycle.
- **Application**: A [Guestbook App](https://github.com/YohanP/guestbook-rust) written in **Rust**.
- **AI Agent**: `kagent` powered by **Google Gemini** but you could change it to use an other provider.

---

## Local Environment Setup

### Prerequisites
- Docker
- k3d
- kubectl

The local environment is designed to be "One-Click" reproducible. Simply execute the bootstrap script to provision the entire lab:

```bash
./scripts/setup.sh
```

After running the setup script, you need to add an entry to your `/etc/hosts` file to resolve `guestbook.local` to your local machine. This is necessary because of the Traefik Ingress configuration used in this setup.

Add the following line to your [`/etc/hosts`](/etc/hosts) file:

```
127.0.0.1 guestbook.local
```

Then you could browse the app here: http://guestbook.local:8080
and to browse ArgoCD UI: http://localhost:8080/

## kagent Setup

The previous steps established a traditional GitOps foundation. Now, we enter the **AI-Ops** territory by deploying `kagent`.

### 1. Installing the CLI
First, we need the `kagent` CLI to bootstrap the agent within our cluster. While Helm is an alternative, the CLI provides the most streamlined experience for this demonstration.

```bash
# Fetch and install the latest kagent binary
curl https://raw.githubusercontent.com/kagent-dev/kagent/refs/heads/main/scripts/get-kagent | bash
```

### 2. Provisioning the Agent in the Cluster
We will use the demo profile for a quick-start installation.

> [!NOTE]
> The OpenAI Quirk: Currently, the kagent install command expects an OPENAI_API_KEY by default. Since our architecture explicitly uses Google Gemini, we bypass this requirement with a placeholder value to proceed with the bootstrap.

```bash
export OPENAI_API_KEY="dontcare" && kagent install --profile demo
```

### 3. Empowering the Agent: "Brain & Hands"

To perform its duties, the agent needs two core capabilities: a reasoning engine (Gemini) and the ability to act on code (GitHub). Kubernetes capabilities are already setup by default.
We store these credentials securely as Kubernetes Secrets in the kagent namespace.
```bash
kubectl create secret generic kagent-gemini \
 -n kagent \
 --from-literal GOOGLE_API_KEY=YOUR_GOOGLE_API_KEY

kubectl create secret generic github-pat \
 -n kagent \
 --from-literal GITHUB_PERSONAL_ACCESS_TOKEN=YOUR_PAT
```

### 4. Defining the SRE Persona

Instead of a generic assistant, we configure a Specialized SRE Agent. This is achieved by applying three specific layers of configuration:

- ModelConfig, see [`kagent/kagent-gemini-config.yaml`](kagent/kagent-gemini-config.yaml): Directs the agent to use Gemini as the primary inference engine.
- MCP Server, see [`kagent/kagent-github-mcp.yaml`](kagent/kagent-github-mcp.yaml): Enables the Model Context Protocol (MCP) for GitHub, granting the agent the "tools" to read/write in the repository.
- Agent Definition, see [`kagent/kagent-devops-expert.yaml`](kagent/kagent-devops-expert.yaml): The final "persona" that combines the model, the tools, and the SRE troubleshooting logic.

```bash
# Apply the Gemini configuration and GitHub connectivity (MCP)
kubectl -n kagent apply -f kagent/kagent-gemini-config.yaml
kubectl -n kagent apply -f kagent/kagent-github-mcp.yaml

# Deploy the final "DevOps Expert" agent definition
kubectl -n kagent apply -f kagent/kagent-devops-expert.yaml
```
