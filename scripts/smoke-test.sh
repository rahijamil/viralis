#!/usr/bin/env bash
# scripts/smoke-test.sh - Post-deployment/rollback smoke tests
# Usage: ./scripts/smoke-test.sh <service|all>

set -euo pipefail

SERVICE="${1:-all}"
NAMESPACE="${NAMESPACE:-production}"
TIMEOUT=60

GREEN='\033[0;32m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'

log_ok()   { printf "${GREEN}OK  %s${NC}\n" "$*"; }
log_err()  { printf "${RED}ERR %s${NC}\n"   "$*"; }
log_info() { printf "${CYAN}... %s${NC}\n"  "$*"; }

ALL_SERVICES="alert analytics crawler dashboard ingestion ingestion-go user"

# Resolve service name to deployment name (bash 3.2 compatible)
svc_to_deploy() {
    case "$1" in
        ingestion)    echo "ingestion-service"    ;;
        ingestion-go) echo "ingestion-go-service" ;;
        crawler)      echo "crawler-service"      ;;
        analytics)    echo "analytics-service"    ;;
        alert)        echo "alert-service"        ;;
        user)         echo "user-service"         ;;
        dashboard)    echo "dashboard"            ;;
        *)            echo ""                      ;;
    esac
}

check_service() {
    local service="$1"
    local deployment
    deployment="$(svc_to_deploy "${service}")"

    if [[ -z "${deployment}" ]]; then
        log_err "Unknown service: ${service}"
        return 1
    fi

    log_info "Smoke-testing ${service} (deployment: ${deployment})..."

    if ! kubectl rollout status "deployment/${deployment}" \
            -n "${NAMESPACE}" --timeout="${TIMEOUT}s" 2>/dev/null; then
        log_err "Rollout status check failed: ${service}"
        return 1
    fi

    local pod
    pod="$(kubectl get pods -n "${NAMESPACE}" -l "app=${deployment}" \
            --field-selector=status.phase=Running \
            -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)"

    if [[ -z "${pod}" ]]; then
        log_err "No running pod found for ${service}"
        return 1
    fi

    if kubectl exec "${pod}" -n "${NAMESPACE}" -- \
            sh -c 'curl -sf http://localhost:8080/health' &>/dev/null; then
        log_ok "Smoke test passed: ${service}"
        return 0
    else
        log_err "Health endpoint failed: ${service} (pod: ${pod})"
        return 1
    fi
}

# ─── Main ─────────────────────────────────────────────────────────────────────
if [[ "${SERVICE}" == "all" ]]; then
    failed=0
    for svc in ${ALL_SERVICES}; do
        check_service "${svc}" || (( failed++ )) || true
    done
    if (( failed > 0 )); then
        log_err "${failed} smoke test(s) failed."
        exit 1
    fi
    log_ok "All smoke tests passed."
else
    check_service "${SERVICE}"
fi
