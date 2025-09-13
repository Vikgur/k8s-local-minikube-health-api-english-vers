# -------- Config --------
PROFILE ?= minikube
NS ?= health-api-dev
HELMFILE ?= helm/helmfile.dev.gotmpl
MINIKUBE_DRIVER ?= docker
CPUS ?= 4
MEMORY ?= 8192
DISK ?= 30g

# -------- Help --------
.DEFAULT_GOAL := help
help:
	@echo "Targets:"
	@echo "  up           -> start + addons + ns + deps + apply"
	@echo "  start        -> minikube start"
	@echo "  addons       -> enable metrics-server & ingress"
	@echo "  ns           -> create namespace ($(NS))"
	@echo "  deps         -> helm repos & chart deps"
	@echo "  diff         -> helmfile diff"
	@echo "  apply        -> helmfile apply"
	@echo "  destroy      -> helmfile destroy"
	@echo "  docker-env   -> use minikube's Docker daemon"
	@echo "  status       -> minikube & kubectl status"
	@echo "  logs         -> tail controller & app pods"
	@echo "  tunnel       -> run minikube tunnel (root)"
	@echo "  stop/delete  -> stop or delete cluster"

# -------- Cluster --------
start:
	minikube start -p $(PROFILE) \
	  --driver=$(MINIKUBE_DRIVER) \
	  --cpus=$(CPUS) --memory=$(MEMORY) --disk-size=$(DISK)

addons:
	minikube -p $(PROFILE) addons enable metrics-server
	minikube -p $(PROFILE) addons enable ingress

ns:
	kubectl get ns $(NS) >/dev/null 2>&1 || kubectl create namespace $(NS)

status:
	minikube -p $(PROFILE) status || true
	kubectl get nodes -o wide
	kubectl get ns | grep $(NS) || true

stop:
	minikube -p $(PROFILE) stop

delete:
	minikube -p $(PROFILE) delete --all --purge

# -------- Docker inside Minikube --------
docker-env:
	@echo "Run: eval $$(minikube -p $(PROFILE) docker-env)"

# -------- Helm/Helmfile --------
deps:
	@# build chart dependencies для локальных чартов
	@for d in helm/*; do \
	  if [ -d $$d ] && [ -f $$d/Chart.yaml ]; then \
	    echo "helm dependency build $$d"; \
	    helm dependency build $$d || exit 1; \
	  fi; \
	done

diff:
	helmfile -f $(HELMFILE) -n $(NS) diff || true

apply:
	helmfile -f $(HELMFILE) -n $(NS) apply

destroy:
	helmfile -f $(HELMFILE) -n $(NS) destroy

# -------- Convenience --------
up: start addons ns deps apply

logs:
	@echo "Controller logs:" && kubectl -n ingress-nginx logs -l app.kubernetes.io/component=controller --tail=50 || true
	@echo "App pods:" && kubectl -n $(NS) get pods -o wide

# Requires root; exposes LoadBalancer services on 127.0.0.1
# Stop with Ctrl+C
# Use in a separate terminal
# sudo make tunnel
tunnel:
	sudo -E minikube -p $(PROFILE) tunnel
