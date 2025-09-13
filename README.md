# Table of Contents

* [About the Project](#about-the-project)
* [Helm/Helmfile Architecture](#helmhelmfile-architecture)
* [Structure](#structure)
  * [Bitnami\_charts/](#bitnami_charts)
  * [helm/](#helm)
  * [helm/helmfile.prod.gotmpl](#helmhelmfileprodgotmpl)
  * [helm/helmfile.dev.gotmpl](#helmhelmfiledevgotmpl)
  * [helm/values](#helmvalues)
* [Requirements Before Launch](#requirements-before-launch)
* [Launch Instructions (Makefile)](#launch-instructions-makefile)
  * [Preparation](#preparation)
  * [Main Commands](#main-commands)
  * [Blue/Green (prod)](#bluegreen-prod)
  * [Canary (prod)](#canary-prod)
* [Blue/Green and Canary Implementation](#bluegreen-and-canary-implementation)
  * [Deployment Strategies](#deployment-strategies)
  * [Deployment Instructions](#deployment-instructions)
    * [1. Blue/Green Deployment](#1-bluegreen-deployment)
    * [2. Verifying the New Release](#2-verifying-the-new-release)
    * [3. Switching Traffic](#3-switching-traffic)
    * [4. Canary Rollout](#4-canary-rollout)
    * [5. Rollback Scenarios](#5-rollback-scenarios)
* [Kubernetes Best Practices in Helm Charts](#kubernetes-best-practices-in-helm-charts)
* [Implemented DevSecOps Practices](#implemented-devsecops-practices)
  * [Security Architecture](#security-architecture)
  * [Coverage](#coverage)
    * [Basic Checks](#basic-checks)
    * [Linters and SAST](#linters-and-sast)
    * [Policy-as-Code](#policy-as-code)
    * [Configuration and Secret Security](#configuration-and-secret-security)
    * [CI/CD and Infrastructure](#cicd-and-infrastructure)
  * [Result](#result)
  * [Running Checks](#running-checks)
    * [OWASP Top-10 Mapping](#owasp-top-10-mapping)

---

# About the Project

This project provides a production-ready deployment infrastructure for the web application [`health-api`](https://github.com/vikgur/health-api-for-microservice-stack-english-vers) using **Helm** and **Helmfile**. The repository contains a complete set of charts for the application services (backend, frontend, nginx, postgres, jaeger, swagger) and manages their rollout across dev and prod environments.

Main goals:

* unified deployment structure for all services within a single `helm/` directory;
* centralized release management using Helmfile;
* convenient environment separation through the order of values file inclusion;
* common base values for all environments, with Blue/Green/Canary overrides;
* reproducible launch via Makefile and CI/CD;
* advanced deployment strategies: Blue/Green and Canary;
* centralized launch via Makefile;
* implementation of modern DevSecOps practices with optimal coverage.

Key features:

* **Unified configuration for all environments** — base values files are shared, differences are placed in separate directories (`values-dev/`, `values/blue/`, `values/green/`, `values/canary/`). The inclusion order defines the target environment.
* **VERSION in production controls both the image and the environment variable**, ensuring a strict binding between code and artifacts.
* The **Helm Monorepo pattern** is applied: all charts and values are stored in a single repository, eliminating version drift and simplifying reproducibility.
* **Blue/Green and Canary strategies** are used: one slot serves production traffic, while the other rolls out and tests the new version.

---

# Helm/Helmfile Architecture

The project is organized under the `helm/` directory, where each service has its own chart (backend, frontend, postgres, nginx, etc.), with release management centralized via `helmfile`.

Values are stored in the `helm/values/` directory, which allows:

* storing base configurations and overrides for different environments in one place,
* easy switching between prod and dev,
* using Blue/Green and Canary without chart duplication.

As a result:

* **transparent structure** — each service has its own chart,
* **reproducible deployment** — environment logic is fully described in helmfile,
* **flexibility ensured** — support for prod/dev and production-grade rollout strategies.

---

# Structure

## Bitnami\_charts/

The project uses the PostgreSQL chart from Bitnami.
Due to access restrictions without VPN, the chart is stored locally in the repository.
This ensures reproducible installation without external dependencies.

## helm/

* **alias-service/** — auxiliary service for working with API aliases.
* **backend/** — Helm chart for the main backend service.
* **frontend/** — Helm chart for the frontend application.
* **infra/** — shared infrastructure (e.g., configs for ingress-nginx or other components).
* **init-db/** — chart for database initialization (schema creation, seed data).
* **jaeger/** — chart for the Jaeger request tracing system.
* **nginx/** — chart for the nginx proxy inside the project.
* **postgres/** — chart for PostgreSQL (project database).
* **swagger/** — chart for swagger-ui (API documentation UI).
* **values/** — values files for all services (separate dev/prod, blue/green/canary).
* **helmfile.dev.gotmpl** — config for deploying the full stack in the dev environment.
* **helmfile.prod.gotmpl** — config for the production environment (with blue/green and canary strategies).
* **rsync-exclude.txt** — exclusion list of dev files for syncing prod files to the master node.

## helm/helmfile.prod.gotmpl

This file serves as the single control point and describes all releases of the production environment. It ensures consistent and reproducible deployment and allows rolling out all chart services of the project in one step: backend, frontend, nginx, postgres, swagger, alias-service, jaeger, init-db, and ingress controller.

It includes:

* paths to charts and values files,
* environment variables (e.g., `VERSION` for images),
* dependencies between services (via `needs`),
* rollout strategies for Blue/Green (two releases per service) and a dedicated Canary release in ingress-nginx.

Additional services:

* **alias-service** — auxiliary service for API alias management, always installed.
* **jaeger** — request tracing service (observability), always installed.
* **init-db** — helper chart for database initialization; disabled by default (`installed: false`), used manually during initial setup.

## helm/helmfile.dev.gotmpl

This file describes all releases of the local environment and is a simplified version of the production config. It is intended for development and debugging: it allows bringing up the full application stack in the `health-api` namespace in a single step.

It includes:

* simplified values from the `helm/values/values-dev/` directory,
* deployed services: backend, frontend, nginx, postgres, swagger, alias-service, jaeger, init-db, ingress-nginx,
* service dependencies (e.g., nginx depends on backend and frontend),
* the `VERSION` variable is taken from the environment and applied to the backend, frontend, and nginx images.

Features:

* **Blue/Green and Canary are not used here**, as this is an environment for development and testing.
* **init-db** can be enabled for quick DB initialization in dev scenarios.
* All services run in a single namespace and are available immediately after `helmfile apply`.

## helm/values

* **blue/** — values for the Blue slot releases (backend, frontend, nginx) serving the production domain.
* **green/** — values for the Green slot releases, where a new version is rolled out for testing before switching.
* **canary/** — values for canary rollouts (ingress with annotations distributing part of the traffic).
* **values-dev/** — simplified values for local development and test environments.

* **backend.yaml** — shared values for the backend service.
* **frontend.yaml** — shared values for the frontend.
* **nginx.yaml** — base config for the nginx proxy.
* **postgres.yaml** — PostgreSQL parameters.
* **jaeger.yaml** — config for the tracing system.
* **swagger.yaml** — config for swagger-ui.

---

# Requirements Before Launch

1. **Helm** (v3) — package manager for Kubernetes.
   Installs charts into the cluster.

2. **Helmfile** — manages groups of Helm releases.
   Works with `helmfile.dev.gotmpl` and `helmfile.prod.gotmpl`.

3. **Helm Diff Plugin** — shows differences between the current state and the new one (`helm plugin install https://github.com/databus23/helm-diff`).
   Required for the `make diff` command.

4. **kubectl** — CLI for working with Kubernetes.
   Helm and Helmfile use kubeconfig to connect to the cluster.

5. **Make** — for running commands via `Makefile`.

6. **Access to a Kubernetes cluster** — a working kubeconfig so Helmfile can deploy releases.

---

# Launch Instructions (Makefile)

## Preparation

Before launch, set the image version:

```bash
export VERSION=1.0.0
```

By default, `ENV=prod` is used. For development, specify `ENV=dev`.

## Main Commands

* `make deploy ENV=prod` — deploy all releases in prod.
* `make deploy ENV=dev` — deploy all releases in dev.
* `make diff ENV=prod` — show the diff before applying.
* `make delete ENV=dev` — delete dev releases.

## Blue/Green (prod)

* `make deploy-blue VERSION=...` — deploy backend, frontend, and nginx in the blue slot.
* `make deploy-green VERSION=...` — deploy backend, frontend, and nginx in the green slot.
* `make switch-blue` — switch the main `nginx` service (alias-service) to the blue slot.
* `make switch-green` — switch the main `nginx` service (alias-service) to the green slot.

## Canary (prod)

* `make set-canary N=10` — route N% of traffic to the new release via ingress-nginx.

---

# Blue/Green and Canary Implementation

Subdomains for `blue` and `green` are registered with the provider. `ingress-nginx` already has an external IP/hostname, and ports 80/443 are open.

* Each service (backend, frontend, nginx) has two versions (blue and green).
* Both variants are deployed simultaneously in Helmfile.
* Traffic switching is done via Service/Ingress: production points either to blue or green.
* QA can verify the new release (green) while users continue working with the old one (blue). After testing, traffic is switched.

## Deployment Strategies

**Blue/Green**

* Two slots (`blue` and `green`) are always running in the cluster.
* The production domain (`health.gurko.ru`) points only to one of them.
* The second slot is used for rollout and validation of a new version.
* After testing, traffic is switched to the new slot, while the old one remains in reserve for quick rollback and then is updated to the stable version.

**Canary**

* Configured through `ingress-nginx` annotations.
* A portion of traffic (e.g., 10%) is routed to the new version, while the rest continues to the current one.
* Allows testing release behavior under real production load without a full switch.

## Deployment Instructions

## 1. Blue/Green Deployment

Deploy both environments in parallel:

```bash
make deploy-blue VERSION=1.0.0
make deploy-green VERSION=1.0.0
```

By default, **Blue** is the primary slot: user traffic goes there since `alias-service` is configured with the selector `track=blue`.

## 2. Verifying the New Release

* QA or a developer checks the `*-green` (or `*-blue`) services in the `health-api` namespace.
* Meanwhile, users continue working with the current environment.

## 3. Switching Traffic

When the new release passes validation:

```bash
make switch-green
```

or

```bash
make switch-blue
```

Traffic immediately goes to the chosen environment, while the old one remains as a rollback reserve.

## 4. Canary Rollout

To gradually enable the new release:

```bash
make set-canary N=10
```

10% of traffic will be routed to the new version via ingress-nginx.
You can increase the percentage (25, 50, 100) while monitoring metrics.

## 5. Rollback Scenarios

If the new release is unstable:

* **Blue/Green:** switch traffic back (`make switch-blue` or `make switch-green`).
* **Canary:** reduce the percentage to `0` or remove the canary release.

If the current release (`blue`) was updated with a bad version:

1. **Disable canary (if enabled):**

```bash
kubectl annotate svc ingress-nginx-controller -n ingress-nginx \
  nginx.ingress.kubernetes.io/canary-weight="0" --overwrite
```

2. **Rollback blue via Helm:**

```bash
helm -n health-api history backend-blue
helm -n health-api rollback backend-blue <REV>
helm -n health-api history frontend-blue
helm -n health-api rollback frontend-blue <REV>
helm -n health-api history nginx-blue
helm -n health-api rollback nginx-blue <REV>
```

3. **Or rollback to a stable image tag:**

```bash
export VERSION=v1.0.XX_stable
helmfile -f helmfile.prod.gotmpl apply --selector name=backend-blue
helmfile -f helmfile.prod.gotmpl apply --selector name=frontend-blue
helmfile -f helmfile.prod.gotmpl apply --selector name=nginx-blue
```

4. **If green contains a stable version — switch to it:**

```bash
make switch-green
```

5. **If green was removed — redeploy it and switch:**

```bash
export VERSION=v1.0.XX_stable
helmfile -f helmfile.prod.gotmpl apply --selector name=backend-green
helmfile -f helmfile.prod.gotmpl apply --selector name=frontend-green
helmfile -f helmfile.prod.gotmpl apply --selector name=nginx-green
make switch-green
```

6. **After rollback:** update the inactive color to the stable version, so both environments are available again for Blue/Green.

---

# Kubernetes Best Practices in Helm Charts

The project implements all key best practices from production use in top-tier companies:

1. **Probes**
   readinessProbe, livenessProbe, startupProbe — monitor readiness, hangs, and initialization.

2. **Resources**
   `resources.requests` and `resources.limits` are set — ensure stability and support HPA.

3. **HPA**
   Automatic scaling by CPU and RAM, all parameters externalized into values.

4. **SecurityContext**
   `runAsNonRoot`, `runAsUser`, `readOnlyRootFilesystem` — run in non-privileged mode.

5. **ServiceAccount + RBAC**
   Services run under dedicated serviceAccounts with restricted RBAC permissions.

6. **PriorityClass**
   `priorityClassName` assigned to manage pod importance.

7. **Affinity & Spread**
   Implemented affinity, nodeSelector, and topologySpreadConstraints for load balancing.

8. **Lifecycle Hooks**
   `preStop`/`postStart` — proper shutdown and initialization.

9. **Graceful Shutdown**
   `terminationGracePeriodSeconds` configured for safe shutdown.

10. **ImagePullPolicy**
    `IfNotPresent` in production for stability, `Always` only in dev/CI.

11. **InitContainers**
    Used for migrations and service readiness checks.

12. **Volumes / PVC**
    Volumes connected, with persistent volumes (PVC) where required.

13. **RollingUpdate Strategy**
    Zero-downtime deployments: `maxSurge: 1`, `maxUnavailable: 0`.

14. **Annotations for Rollout**
    `checksum/config`, `checksum/secret` used — trigger restarts on config/secret changes.

15. **Tolerations**
    Support for taints where needed.

16. **Helm Helpers**
    Templates in `_helpers.tpl` for DRY, standardized names and labels.

17. **Secrets (fine-grained access)**
    `POSTGRES_PASSWORD` securely injected from Kubernetes Secret via `valueFrom.secretKeyRef`.

18. **Multienv Helmfile**
    Using `helmfile.dev.yaml` and `helmfile.prod.yaml` with different sets of values files (`values-dev/` and `values/`). All charts are shared, environments differ only by configuration.

# Implemented DevSecOps Practices

The project is built around the secure Blue/Green + Canary pattern. DevSecOps practices are integrated as a mandatory layer of control and automated checks at the Helm/Helmfile level.

**Required tools for checks:** `helm`, `helmfile`, `helm-diff`, `trivy`, `checkov`, `conftest` (OPA), `gitleaks`, `make`, `pre-commit`

## Security Architecture

* **.gitleaks.toml** — rules for secret scanning, with exclusions for Helm templates.
* **.trivyignore** — list of false positives for the misconfiguration scanner.
* **policy/helm/security.rego** — OPA/Conftest policies (forbid privileged, require resources, etc.).
* **policy/helm/security\_test.rego** — unit tests for policies.
* **.checkov.yaml** — Checkov config for static analysis of Kubernetes manifests.
* **Makefile** — `lint`, `scan`, `opa` targets to run checks with a single command.
* **.gitignore** — excludes temporary and sensitive artifacts: chart tarballs (`*.tgz`), local dev-values, scanner reports, IDE files, and encrypted values (`*.enc.yaml`, `*.sops.yaml`).

## Coverage

### Basic Checks

* **helm lint** — chart syntax and structure validation.
* **kubeconform** — validation against Kubernetes API.
  → Secure SDLC: early error detection.

### Linters and SAST

* **checkov**, **trivy config** — analyze Helm/manifests for insecure patterns.
* **kubesec** — check securityContext and capabilities.
  → Compliance with OWASP IaC Security and CIS Benchmarks.

### Policy-as-Code

* **OPA/Conftest** — strict rules: forbid privileged, enforce runAsNonRoot, require resources.
  → OWASP Top-10: A4 Insecure Design, A5 Security Misconfiguration.

### Configuration and Secret Security

* **helm-secrets / sops** — encryption of sensitive values.
* **gitleaks** — secret scanning in code and commits.
  → OWASP: A2 Cryptographic Failures, A3 Injection, A5 Security Misconfiguration.

### Pre-commit

* **.pre-commit-config.yaml** — defines hooks that run checks (`yamllint`, `gitleaks`, `helm lint`, `trivy`, `checkov`, `conftest`) on every commit.
* Ensures that errors and secrets are blocked from Git even before CI/CD.

### CI/CD and Infrastructure

* **Makefile** — single entry point for DevSecOps checks (`make lint`, `make scan`, `make opa`).
* **Helmfile diff** — dry-run before rollout.
  → OWASP A1 Broken Access Control: minimize manual actions and errors.

## Result

Key DevSecOps practices implemented: linters, SAST, Policy-as-Code, secret scanning, and secret management. Protection is ensured against major OWASP Top-10 categories (Security Misconfiguration, Insecure Design, Cryptographic Failures, Broken Access Control, Secrets Management). The configuration is reproducible and secure: no secrets or artifacts are committed to Git.

## Running Checks

All checks are unified into commands:

```bash
make lint
make scan
make opa
```

### OWASP Top-10 Mapping

Brief mapping of project practices to OWASP Top-10:

* **A1 Broken Access Control** → management via `alias-service`, unified `nginx` service, minimized manual switching.
* **A2 Cryptographic Failures** → no secrets stored in values; leak detection via gitleaks; (optional) helm-secrets/sops for encryption.
* **A3 Injection** → no hardcoded credentials; linters and static analysis (helm lint, trivy config, checkov).
* **A4 Insecure Design** → OPA/Conftest policies: forbid privileged, require resources, enforce runAsNonRoot.
* **A5 Security Misconfiguration** → helm lint, kubeconform, checkov; deny by default for ingress/services.
* **A6 Vulnerable and Outdated Components** → pinned chart and image versions; scanning with trivy.
* **A7 Identification and Authentication Failures** → partial: GHCR registry secrets stored securely, but no dedicated RBAC for helm infra yet.
* **A8 Software and Data Integrity Failures** → helmfile diff and CI/CD pipeline; image signing (cosign when using GHCR).
* **A9 Security Logging and Monitoring Failures** → partial: observability services (jaeger, prometheus) included, centralized logging (e.g., Loki) planned.
* **A10 SSRF** → not applicable to Helm/Helmfile; controlled at application and WAF level.
