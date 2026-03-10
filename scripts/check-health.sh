#!/usr/bin/env bash
# scripts/check-health.sh - Periodic health checks for auto-rollback triggers
# Used by the auto-rollback GitHub Actions workflow (scheduled every 5 mins).

set -euo pipefail

NAMESPACE="${NAMESPACE:-production}"
THRESHOLD_ERROR_RATE=5   # percent
THRESHOLD_LATENCY_MS=500 # milliseconds (p95)

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'

SERVICES=(ingestion-service crawler-service analytics-service alert-service user-service dashboard ingestion-go-service)

failed=0

log_fail() { printf "${RED}❌ %s${NC}\n"    "$*"; }
log_ok()   { printf "${GREEN}✅ %s${NC}\n"  "$*"; }
log_warn() { printf "${YELLOW}⚠️  %s${NC}\n" "$*"; }

# ─── Pod status ───────────────────────────────────────────────────────────────
check_pods() {
    local deployment="$1"

    if ! kubectl get deployment "${deployment}" -n "${NAMESPACE}" &>/dev/null; then
        log_warn "${deployment}: not deployed yet — skipping"
        return 0
    fi

    local desired ready
    desired="$(kubectl get deployment "${deployment}" -n "${NAMESPACE}" \
        -o jsonpath='{.spec.replicas}' 2>/dev/null || echo 0)"
    ready="$(kubectl get deployment "${deployment}" -n "${NAMESPACE}" \
        -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo 0)"

    if [[ "${ready}" -lt "${desired}" ]]; then
        log_fail "${deployment}: only ${ready}/${desired} pods ready"
        return 1
    fi

    log_ok "${deployment}: ${ready}/${desired} pods ready"
}

# ─── Prometheus query (optional) ──────────────────────────────────────────────
# If Prometheus is available, query error rate. Gracefully skipped otherwise.
check_error_rate() {
    local service="$1"
    local prom_url="${PROMETHEUS_URL:-}"

    [[ -z "${prom_url}" ]] && return 0  # Skip if Prometheus not configured

    local query="sum(rate(http_requests_total{status=~'5..',service='${service}'}[5m])) \
/ sum(rate(http_requests_total{service='${service}'}[5m])) * 100"

    local rate
    rate="$(curl -sf "${prom_url}/api/v1/query" \
        --data-urlencode "query=${query}" | \
        python3 -c "import sys,json; d=json.load(sys.stdin); \
            r=d['data']['result']; print(r[0]['value'][1] if r else '0')" 2>/dev/null || echo 0)"

    if (( $(echo "${rate} > ${THRESHOLD_ERROR_RATE}" | bc -l 2>/dev/null || echo 0) )); then
        log_fail "${service}: error rate ${rate}% > threshold ${THRESHOLD_ERROR_RATE}%"
        return 1
    fi
}

# ─── Main ─────────────────────────────────────────────────────────────────────
echo "Running health checks in namespace '${NAMESPACE}'…"

for svc in "${SERVICES[@]}"; do
    check_pods "${svc}"  || (( failed++ )) || true
    check_error_rate "${svc}" || (( failed++ )) || true
done

if (( failed > 0 )); then
    printf "${RED}❌ %d health check(s) failed — auto-rollback may be triggered.${NC}\n" "${failed}"
    exit 1
fi

printf "${GREEN}✅ All health checks passed.${NC}\n"
exit 0
