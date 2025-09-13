.PHONY: deploy diff delete deploy-blue deploy-green switch-blue switch-green set-canary

# Variables
ENV ?= prod
VERSION ?= latest
N ?= 10  # percentage of traffic for canary

# Basic targets
deploy:
	helmfile -f helmfile.$(ENV).gotmpl apply

diff:
	helmfile -f helmfile.$(ENV).gotmpl diff

delete:
	helmfile -f helmfile.$(ENV).gotmpl destroy

# -----------------------------
# Blue/Green Deployment (prod)
# -----------------------------

deploy-blue:
	helmfile -f helmfile.prod.gotmpl apply --selector name=backend-blue
	helmfile -f helmfile.prod.gotmpl apply --selector name=frontend-blue
	helmfile -f helmfile.prod.gotmpl apply --selector name=nginx-blue

deploy-green:
	helmfile -f helmfile.prod.gotmpl apply --selector name=backend-green
	helmfile -f helmfile.prod.gotmpl apply --selector name=frontend-green
	helmfile -f helmfile.prod.gotmpl apply --selector name=nginx-green

# Switch active slot via alias-service (stable Service `nginx`)
switch-blue:
	TRACK=blue helmfile -f helmfile.prod.gotmpl apply --selector name=alias-service




switch-green:
	TRACK=green helmfile -f helmfile.prod.gotmpl apply --selector name=alias-service

# -----------------------------
# Canary Rollout (prod)
# -----------------------------

# Set canary traffic percentage (default N=10)
set-canary:
	helmfile -f helmfile.prod.gotmpl apply --selector name=ingress-nginx-canary
	kubectl annotate svc ingress-nginx-controller -n ingress-nginx \
		nginx.ingress.kubernetes.io/canary-weight="$(N)" --overwrite

.PHONY: lint scan opa

lint:
	helm lint ./backend ./frontend ./nginx

scan:
	trivy config ./helm
	checkov -d ./helm

opa:
	conftest test -p policy/helm ./helm --all-namespaces
