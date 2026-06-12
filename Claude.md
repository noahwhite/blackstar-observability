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
