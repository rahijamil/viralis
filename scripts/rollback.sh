#!/usr/bin/env bash
# scripts/rollback.sh - Multi-service rollback automation for Viralis
# Usage: ./scripts/rollback.sh [SERVICE] [OPTIONS]

set -euo pipefail

# ─── Configuration ────────────────────────────────────────────────────────────
NAMESPACE="${NAMESPACE:-production}"
LOG_DIR="${LOG_DIR:-logs}"
LOG_FILE="${LOG_DIR}/rollback-$(date +%Y%m%d-%H%M%S).log"
SLACK_WEBHOOK="${SLACK_WEBHOOK:-}"
ROLLBACK_TIMEOUT=120  # 2 minutes
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ─── Colours ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# ─── Service list ─────────────────────────────────────────────────────────────
ALL_SERVICES="alert analytics crawler dashboard ingestion ingestion-go user"

# Resolve service name → deployment name (bash 3.2-compatible)
service_to_deployment() {
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

# ─── Helpers ──────────────────────────────────────────────────────────────────
mkdir -p "${LOG_DIR}"

log() {
    local level="$1"; shift
    local ts; ts="$(date '+%Y-%m-%d %H:%M:%S')"
    local colour="${NC}"
    case "${level}" in
        INFO)  colour="${CYAN}"   ;;
        OK)    colour="${GREEN}"  ;;
        WARN)  colour="${YELLOW}" ;;
        ERROR) colour="${RED}"    ;;
    esac
    printf "${colour}[%s] [%-5s] %s${NC}\n" "${ts}" "${level}" "$*" | tee -a "${LOG_FILE}"
}

show_help() {
    cat <<EOF
${CYAN}Viralis Rollback Automation${NC}

Usage:
  ./scripts/rollback.sh <service>              Roll back a single service
  ./scripts/rollback.sh --all                  Roll back all services
  ./scripts/rollback.sh <service> --to <tag>   Roll back to a specific image tag

Options:
  --all              Target all services
  --to  <tag>        Image tag / digest to roll back to (e.g. main-a1b2c3d)
  --namespace <ns>   Kubernetes namespace  (default: production)
  --dry-run          Show what would happen without changing anything
  --auto-trigger     Flag used by CI/CD pipelines (affects log trigger label)
  --help             Show this help

Services:
  ${ALL_SERVICES}

Examples:
  ./scripts/rollback.sh ingestion
  ./scripts/rollback.sh analytics --to main-a1b2c3d
  ./scripts/rollback.sh --all --dry-run
  ./scripts/rollback.sh --all --auto-trigger
EOF
}

# ─── Slack notification ───────────────────────────────────────────────────────
notify_slack() {
    local status="$1" service="$2" from_ver="$3" to_ver="$4" trigger="$5"
    [[ -z "${SLACK_WEBHOOK}" ]] && return 0

    local colour emoji
    if [[ "${status}" == "success" ]]; then colour="good";   emoji="✅"
    else                                   colour="danger";  emoji="❌"; fi

    curl -sf -X POST -H 'Content-type: application/json' \
        --data "{
            \"attachments\":[{
                \"color\":\"${colour}\",
                \"title\":\"${emoji} Rollback ${status}: ${service}\",
                \"fields\":[
                    {\"title\":\"From\",      \"value\":\"${from_ver}\",  \"short\":true},
                    {\"title\":\"To\",        \"value\":\"${to_ver}\",    \"short\":true},
                    {\"title\":\"Trigger\",   \"value\":\"${trigger}\",   \"short\":true},
                    {\"title\":\"Namespace\", \"value\":\"${NAMESPACE}\", \"short\":true}
                ],
                \"footer\":\"Rollback Automation\",
                \"ts\":$(date +%s)
            }]
        }" "${SLACK_WEBHOOK}" || true
}

# ─── Version helpers ──────────────────────────────────────────────────────────
get_current_image() {
    local deployment="$1"
    kubectl get deployment "${deployment}" -n "${NAMESPACE}" \
        -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null || echo "unknown"
}

# ─── Single-service rollback ──────────────────────────────────────────────────
rollback_service() {
    local service="$1" target_ver="$2" trigger="$3"
    local deployment
    deployment="$(service_to_deployment "${service}")"

    if [[ -z "${deployment}" ]]; then
        log ERROR "Unknown service: '${service}'. Run --help to see valid services."
        return 1
    fi

    log INFO "Starting rollback for service '${service}' (deployment: ${deployment})"

    local current_image
    current_image="$(get_current_image "${deployment}")"
    local to_ver="${target_ver:-<previous revision>}"

    log INFO "  From : ${current_image}"
    log INFO "  To   : ${to_ver}"
    log INFO "  NS   : ${NAMESPACE}"

    if [[ "${DRY_RUN}" == "true" ]]; then
        log WARN "[DRY-RUN] Would roll back '${service}' to '${to_ver}'"
        return 0
    fi

    # Verify deployment exists in the cluster
    if ! kubectl get deployment "${deployment}" -n "${NAMESPACE}" &>/dev/null; then
        log WARN "Deployment '${deployment}' not found in namespace '${NAMESPACE}'. Skipping."
        return 0
    fi

    # Perform the rollback
    if [[ -n "${target_ver}" ]]; then
        log INFO "Setting image to '${target_ver}' for deployment '${deployment}'..."
        kubectl set image "deployment/${deployment}" \
            "${deployment}=${target_ver}" -n "${NAMESPACE}"
    else
        log INFO "Running 'kubectl rollout undo' for deployment '${deployment}'..."
        kubectl rollout undo "deployment/${deployment}" -n "${NAMESPACE}"
    fi

    # Poll until rolled-out or timed out
    local elapsed=0
    while (( elapsed < ROLLBACK_TIMEOUT )); do
        local rollout_status
        rollout_status="$(kubectl rollout status "deployment/${deployment}" \
            -n "${NAMESPACE}" --timeout=5s 2>&1 || true)"

        if echo "${rollout_status}" | grep -q "successfully rolled out"; then
            log OK "Rollback complete for '${service}'"
            notify_slack "success" "${service}" "${current_image}" "${to_ver}" "${trigger}"

            if [[ -f "${SCRIPT_DIR}/smoke-test.sh" ]]; then
                log INFO "Running smoke tests for '${service}'..."
                bash "${SCRIPT_DIR}/smoke-test.sh" "${service}" || \
                    log WARN "Smoke tests failed after rollback of '${service}'"
            fi

            if [[ -f "${SCRIPT_DIR}/track-rollback.py" ]]; then
                python3 "${SCRIPT_DIR}/track-rollback.py" track \
                    "${service}" "${current_image}" "${to_ver}" "${trigger}" "success" || true
            fi

            return 0
        fi

        sleep 5
        elapsed=$(( elapsed + 5 ))
    done

    log ERROR "Rollback timed out for '${service}' after ${ROLLBACK_TIMEOUT}s"
    notify_slack "failure" "${service}" "${current_image}" "${to_ver}" "${trigger}"

    if [[ -f "${SCRIPT_DIR}/track-rollback.py" ]]; then
        python3 "${SCRIPT_DIR}/track-rollback.py" track \
            "${service}" "${current_image}" "${to_ver}" "${trigger}" "timeout" || true
    fi

    return 1
}

# ─── All-services rollback ────────────────────────────────────────────────────
rollback_all() {
    local target_ver="$1" trigger="$2"
    local failed=0
    log INFO "Rolling back ALL services in namespace '${NAMESPACE}'..."

    for service in ${ALL_SERVICES}; do
        rollback_service "${service}" "${target_ver}" "${trigger}" || (( failed++ )) || true
    done

    if (( failed == 0 )); then
        log OK "All services rolled back successfully."
    else
        log ERROR "${failed} service(s) failed to roll back."
        return 1
    fi
}

# ─── Argument parsing ─────────────────────────────────────────────────────────
SERVICE=""
TARGET_VERSION=""
ROLLBACK_ALL=false
DRY_RUN=false
AUTO_TRIGGER=false

while (( $# > 0 )); do
    case "$1" in
        --all)          ROLLBACK_ALL=true;      shift ;;
        --to)           TARGET_VERSION="$2";    shift 2 ;;
        --namespace)    NAMESPACE="$2";         shift 2 ;;
        --dry-run)      DRY_RUN=true;           shift ;;
        --auto-trigger) AUTO_TRIGGER=true;      shift ;;
        --help|-h)      show_help;              exit 0 ;;
        -*)             log ERROR "Unknown option: $1"; show_help; exit 1 ;;
        *)              SERVICE="$1";           shift ;;
    esac
done

# ─── Main ─────────────────────────────────────────────────────────────────────
TRIGGER="manual"
[[ "${AUTO_TRIGGER}" == "true" ]] && TRIGGER="auto (CI/CD)"

log INFO "Viralis Rollback Automation — trigger: ${TRIGGER}, dry-run: ${DRY_RUN}"

if [[ "${ROLLBACK_ALL}" == "true" ]]; then
    rollback_all "${TARGET_VERSION}" "${TRIGGER}"
elif [[ -n "${SERVICE}" ]]; then
    rollback_service "${SERVICE}" "${TARGET_VERSION}" "${TRIGGER}"
else
    log ERROR "No service specified and --all not given."
    show_help
    exit 1
fi
