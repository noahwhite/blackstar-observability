# CLAUDE.md

## Project Overview

This repository manages the observability infrastructure for the Blackstar homelab via OpenTofu. It provisions and configures Grafana Cloud resources for monitoring a Proxmox VE / Ceph / Talos Kubernetes cluster.

Primary goals:

* Grafana Cloud provisioning via OpenTofu
* Centralized monitoring for bare-metal Proxmox nodes
* Temperature, disk health, and system metrics collection
* Alerting on threshold violations
* Future support for Ceph and Talos cluster observability

This is a standalone homelab project, separate from the Officina production infrastructure.

---

## Environment Context

Monitored infrastructure:

* HP EliteDesk 800 G9 Mini nodes running Proxmox VE 9.x
* Provisioned via blackstar-pxe-stack and blackstar-ansible
* Nodes are on a home LAN (192.168.1.0/24) with Tailscale overlay networking
* Metrics collection via Grafana Alloy and prometheus-node-exporter on each node
* Metrics shipped to Grafana Cloud via remote write

---

## Architectural Principles

### 1. Prefer Simplicity

* Static configuration over dynamic discovery
* Minimal moving parts
* Deterministic behavior

### 2. Secrets Management

* Never commit secrets, API keys, or tokens to this repository
* Use environment variables or a secrets manager for sensitive values
* Grafana Cloud API keys and tokens must come from external sources at apply time

### 3. Infrastructure as Code

* All Grafana Cloud resources managed via OpenTofu
* No manual configuration in the Grafana Cloud UI that isn't captured here
* Pin provider versions explicitly

### 4. Separation of Concerns

* This repo manages Grafana Cloud resources (datasources, dashboards, alert rules, contact points)
* blackstar-ansible manages agent installation and configuration on nodes (Alloy, node_exporter)
* blackstar-pxe-stack manages bare-metal provisioning

---

## Repository Structure

Expected structure:

```text
Claude.md
LICENSE
README.md

opentofu/
  envs/
    prod/
  modules/
```

---

## Coding Standards

### OpenTofu

* Pin provider versions in `versions.tofu`
* Use consistent formatting (`tofu fmt`)
* Align `=` signs within contiguous key-value groups
* Use modules for reusable components
* Use variables for environment-specific values

### Shell Scripts

* `set -euo pipefail`
* shellcheck-clean
* Explicit error handling

### YAML

* Consistent indentation
* Deterministic ordering

---

## Commit Standards

* No `Co-Authored-By` trailer in commits
* Concise commit messages focused on the "why"

---

## Dashboard Update Workflow

The Grafana provider's `grafana_dashboard` resource uses a `DiffSuppressFunc` on `config_json` that normalizes dashboard JSON before comparing. This can suppress legitimate diffs — particularly deep nested changes like Canvas panel background images.

When `tofu plan` shows "No changes" but the `.tofu` file clearly differs from what's in Grafana:

1. Use `curl` to update the dashboard directly via the Grafana API
2. Run `tofu apply -refresh-only -auto-approve` to sync state
3. Verify with `tofu plan` that state matches configuration

```bash
# Fetch, modify, and save dashboard
curl -s -H "Authorization: Bearer $BLACKSUN_GRAFANA_SA_TOKEN" \
  "https://separationofconcerns0dev.grafana.net/api/dashboards/uid/<UID>" \
  | python3 modify_dashboard.py > /tmp/update.json

curl -s -X POST -H "Authorization: Bearer $BLACKSUN_GRAFANA_SA_TOKEN" \
  -H "Content-Type: application/json" -d @/tmp/update.json \
  "https://separationofconcerns0dev.grafana.net/api/dashboards/db"

# Sync state
TF_VAR_grafana_sa_token="$BLACKSUN_GRAFANA_SA_TOKEN" \
  tofu -chdir=opentofu/envs/prod apply -refresh-only -auto-approve
```

Dashboard UID: `4a378615-30d4-4624-95f4-d74e61ea61fc`

For normal changes (adding panels, modifying queries, thresholds), `tofu plan` and `tofu apply` work correctly. The API workaround is only needed for deeply nested JSON changes that the provider's diff suppression misses.

---

## Validation

Before committing changes:

* Run `tofu fmt -check -recursive`
* Run `tofu validate`
* Verify no secrets are staged

---

## Security

* Repository is public — never commit credentials, tokens, or API keys
* Grafana Cloud API tokens must be provided via environment variables
* Service account keys should have minimum required permissions
