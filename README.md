# Table of Contents

- [About the Project](#about-the-project)  
  - [Choice: Minikube](#choice-minikube)  
- [Core Kubernetes Objects](#core-kubernetes-objects)  
- [Helm/Helmfile](#helmhelmfile)  
  - [Helm Chart Structure](#helm-chart-structure)  
  - [Configuration Flexibility](#configuration-flexibility)  
  - [Helm/Helmfile Architecture](#helmhelmfile-architecture)  
- [Structure](#structure)  
  - [Bitnami_charts/](#bitnami_charts)  
  - [helm/](#helm)  
  - [helm/helmfile.dev.gotmpl](#helmhelmfiledevgotmpl)  
  - [helm/values](#helmvalues)  
- [Requirements Before Launch](#requirements-before-launch)  
  - [Minikube Sanity Check](#minikube-sanity-check)  
- [Minikube](#minikube)  
  - [Minikube Drivers](#minikube-drivers)  
  - [Minikube Architecture (1 VM)](#minikube-architecture-1-vm)  
  - [Key Components](#key-components)  
- [Instruction (Makefile)](#instruction-makefile)  
  - [Preparation](#preparation)  
  - [Main Commands](#main-commands)  
  - [Notes](#notes)  
- [Kubernetes Best Practices in Helm Charts](#kubernetes-best-practices-in-helm-charts)  
- [Implemented DevSecOps Practices](#implemented-devsecops-practices)  
  - [Security Architecture](#security-architecture)  
  - [Coverage](#coverage)  
    - [Basic Checks](#basic-checks)  
    - [Linters and SAST](#linters-and-sast)  
    - [Policy-as-Code](#policy-as-code)  
    - [Secrets Configuration and Security](#secrets-configuration-and-security)  
    - [CI/CD and Infrastructure](#cicd-and-infrastructure)  
  - [Result](#result)  
  - [Running Checks](#running-checks)  
    - [OWASP Top-10 Compliance](#owasp-top-10-compliance)  

---

# About the Project

This project provides a local **Kubernetes (k8s)**-based infrastructure for deploying the [`health-api`](https://github.com/vikgur/health-api-for-microservice-stack-english-vers) web application using **Minikube**, **Helm**, and **Helmfile**. The repository is designed to quickly spin up the full application stack (backend, frontend, nginx, postgres, jaeger, swagger) in a dev environment on a local machine.  
A local cluster is required for debugging Helm charts, testing CI/CD logic, and safely validating changes without risking the production environment.

## Key Objectives

* local playground for testing Helm charts and deployment logic;  
* unified structure for charts and values inside the `helm/` directory;  
* centralized release management with Helmfile;  
* dev-specific overrides stored in `values-dev/`;  
* reproducible quick start via [Makefile](#instruction-via-makefile);  
* potential integration with CI/CD and GitOps workflows;  
* DevSecOps practices integrated for validating local configuration.  

## Features

* **Minikube** emulates a Kubernetes cluster locally in a single VM.  
* **Unified configuration**: base values are shared, dev-specific configs are separated into `values-dev/`.  
* **Makefile** provides a single interface: start Minikube, install dependencies, deploy, clean up.  
* Full application stack supported (backend, frontend, postgres, nginx, swagger, jaeger), allowing a local “mini-prod” setup.  
* Locally downloaded charts (`bitnami_charts/`) ensure reproducibility without relying on external sources.  

## Choice: Minikube

* Full-featured Kubernetes in a single VM — same objects and API as in the cloud.  
* Quick start — installed with a single command, no manual control plane setup.  
* Convenience — built-in addons (ingress, metrics-server).  
* Isolation — cluster can be started and removed without leaving traces.  
* Compatibility — all charts and manifests work the same way as in production.  

---

# Core Kubernetes Objects

Kubernetes defines the basic objects from which applications in the cluster are built:

* **Pod** — the smallest unit of execution (1+ containers).  
  Commands: `kubectl get pods`, `kubectl describe pod <name>`  
* **Deployment** — manages Pods: updates, scaling.  
  Commands: `kubectl get deployments`, `kubectl rollout restart deployment <name>`  
* **Service** — exposes Pods (ClusterIP, NodePort, LoadBalancer).  
  Commands: `kubectl get svc`, `kubectl port-forward svc/<name> 8080:80`  
* **ConfigMap** — stores configurations (env, files).  
  Commands: `kubectl get configmaps`, `kubectl create configmap <name> --from-literal=KEY=VALUE`  
* **Secret** — stores sensitive data (passwords, keys).  
  Commands: `kubectl get secrets`, `kubectl create secret generic <name> --from-literal=PASS=123`  
* **Ingress** — routes external HTTP/HTTPS traffic.  
  Commands: `kubectl get ingress`, `kubectl describe ingress <name>`  
* **Volume / PersistentVolumeClaim** — attaches storage to Pods.  
  Commands: `kubectl get pvc`, `kubectl describe pvc <name>`  
* **Namespace** — isolates resources.  
  Commands: `kubectl get ns`, `kubectl create ns dev`  

> These objects describe the state of the cluster. They can be managed manually with `kubectl`, while Helm provides automation and templating.  

---

# Helm/Helmfile

Helm packages Kubernetes objects into charts, and Helmfile centralizes release management.

## Helm Chart Structure

* **Chart.yaml** — metadata: name, version, dependencies.  
* **values.yaml** — default values (images, resources, ports).  
* **templates/** — directory with Kubernetes manifests as templates.  
* **values/** — extracted values for services (`backend.yaml`, `nginx.yaml`, `postgres.yaml`).  
* **values-dev/** — overrides for the dev environment (minimal resources, persistence disabled).  

## Configuration Flexibility

Helm allows you to:  
- change resources and environment parameters without rewriting templates;  
- apply `values-dev/` for local development;  
- store base service parameters in `helm/values/`;  
- use StatefulSet instead of Deployment if needed, and add HPA, NetworkPolicy, or PDB.  

## Helm/Helmfile Architecture

All charts are located in the `helm/` directory. Release management is delegated to `helmfile`, which applies the required values for dev.  

As a result:  
- **transparent structure** — each service has its own chart;  
- **reproducible deployment** — environments are fully described in helmfile;  
- **flexibility ensured** — both prod and dev can run in a single consistent framework.  

---

# Structure

## Bitnami_charts/

The project uses the PostgreSQL chart from Bitnami.  
Due to VPN restrictions, the chart is stored locally in the repository.  
This guarantees reproducible installation without external dependencies.

## helm/

- **alias-service/** — helper service for working with API aliases.  
- **backend/** — Helm chart for the main backend service.  
- **frontend/** — Helm chart for the frontend application.  
- **infra/** — shared infrastructure (e.g., configs for ingress-nginx or other components).  
- **init-db/** — chart for database initialization (schemas, seed data).  
- **jaeger/** — chart for the Jaeger tracing system.  
- **nginx/** — chart for the internal nginx proxy.  
- **postgres/** — chart for PostgreSQL (project database).  
- **swagger/** — chart for swagger-ui (API documentation UI).  
- **values/** — values files for all services (with separate dev/prod).  
- **helmfile.dev.gotmpl** — config for deploying the full stack in the dev environment.  
- **helmfile.prod.gotmpl** — config for the production environment (with blue/green and canary strategies).  
- **rsync-exclude.txt** — list of dev-file exclusions when syncing prod files to the master node.

## helm/helmfile.dev.gotmpl

This file describes all releases for the local dev environment and serves as a simplified version of the production config. It is intended for development and debugging: enabling a full application stack to be launched in the `health-api` namespace in one step.  

It includes:  
- simplified values from `helm/values/values-dev/`,  
- deployed services: backend, frontend, nginx, postgres, swagger, alias-service, jaeger, init-db, ingress-nginx,  
- service dependencies (e.g., nginx depends on backend and frontend),  
- the `VERSION` variable taken from the environment and injected into backend, frontend, and nginx images.  

## helm/values

- **values-dev/** — simplified values for local development and test environment.  

- **backend.yaml** — common values for the backend service.  
- **frontend.yaml** — common values for the frontend.  
- **nginx.yaml** — base config for the nginx proxy.  
- **postgres.yaml** — PostgreSQL parameters.  
- **jaeger.yaml** — config for the tracing system.  
- **swagger.yaml** — config for swagger-ui.  

---

# Requirements Before Launch

1. **Helm** (v3) — package manager for Kubernetes.  
   Installs charts into the cluster.  

2. **Helmfile** — manages groups of Helm releases.  
   Works with `helmfile.dev.gotmpl`.  

3. **Helm Diff Plugin** — shows the difference between the current and the new state (`helm plugin install https://github.com/databus23/helm-diff`).  
   Required for the `make diff` command.  

4. **kubectl** — CLI for interacting with Kubernetes.  
   Helm and Helmfile use kubeconfig to connect to the cluster.  

5. **Make** — used to run commands via `Makefile`.  

6. **Minikube** — local Kubernetes cluster.  
   Used as a playground. Requires a driver (e.g., Docker).  

7. **Namespace** — created before deployment:  
   ```bash
   kubectl create namespace health-api-dev || true
   ```  

8. **Metrics Server** — must be enabled manually in Minikube:  
   ```bash
   minikube addons enable metrics-server
   ```  

9. **Ingress Controller** — Minikube provides a built-in ingress-nginx addon:  
   ```bash
   minikube addons enable ingress
   ```  

## Minikube Sanity Check

Start Minikube (launch container and services):  
```bash
minikube start
```

Check cluster status:  
```bash
minikube status
```

---

# Minikube

A local Kubernetes cluster is deployed using **Minikube**. It reproduces the architecture of a real Kubernetes cluster inside a single VM and allows running and testing the project locally in conditions close to production.

* **Minikube** launches a single virtual node (`minikube`) in Docker.  
* Inside run `kubelet` and `kube-apiserver` — a full Kubernetes cluster.  
* **kubectl** — CLI client for interacting with the API server.  
* Command `kubectl get nodes` shows one node `minikube` in Ready state.  

On this node you can create all standard Kubernetes objects: Deployment, Service, Pod, etc. All pods run inside this VM.

## Minikube Drivers

* **Docker** — Minikube creates a container with a Kubernetes VM.  
* **VirtualBox** — Minikube spins up a full VM in VirtualBox (accessible via `minikube ssh`).  
* In both cases, the result is a full-fledged Kubernetes VM.  

For this project, the **Docker** driver is used.

## Minikube Architecture (1 VM)

[minikube VM]  
├── kube-apiserver  
├── kubelet  
├── container runtime  
├── etcd  
├── CoreDNS  
├── kube-proxy  
├── kube-scheduler  
├── kube-controller-manager  
├── ingress-controller (opt.)  
└── Pods: backend, frontend, nginx  

## Key Components

1. **kube-apiserver** — accepts all kubectl/CI commands.  
2. **etcd** — stores the cluster state.  
3. **kube-scheduler** — selects a node for pod placement.  
4. **kube-controller-manager** — ensures desired and actual states match.  
5. **kubelet** — runs containers.  
6. **kube-proxy** — networking between Pods and Services.  
7. **container runtime** — physically runs containers.  
8. **CoreDNS** — DNS inside the cluster.  
9. **ingress-controller** — routes external traffic inside the cluster.  
10. **metrics-server** — CPU/RAM metrics (`kubectl top`).  

---

# Instruction (Makefile)

## Preparation

Before running, you need to start the Minikube cluster and enable the required addons:

```bash
make up
```

Default namespace is `health-api-dev`. It can be changed with the `NS` variable.

## Main Commands

* `make up` — start Minikube, enable addons, create namespace, install dependencies, and deploy releases.  
* `make start` — start the Minikube cluster.  
* `make addons` — enable metrics-server and ingress.  
* `make ns` — create namespace `health-api-dev`.  
* `make deps` — update Helm repos and build local chart dependencies.  
* `make diff` — show differences before applying (helmfile diff).  
* `make apply` — apply all releases (helmfile apply).  
* `make destroy` — delete all releases (helmfile destroy).  
* `make stop` — stop the Minikube cluster.  
* `make delete` — completely remove the Minikube cluster.  
* `make status` — show Minikube and node status.  
* `make logs` — logs of ingress-controller and list of application pods.  
* `make docker-env` — use Minikube’s Docker daemon (for building images locally).  
* `make tunnel` — expose LoadBalancer services on localhost (requires root).  

## Notes

* Minikube is used as a **local dev environment**, closely resembling production.  
* `helmfile.dev.gotmpl` connects base values and overrides from `values-dev/`.  
* All services (backend, frontend, postgres, nginx, swagger, jaeger) run inside a single Minikube node.  

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