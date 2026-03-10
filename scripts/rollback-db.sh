#!/usr/bin/env bash
# scripts/rollback-db.sh - Database migration rollback for Python Alembic services
# Usage: ./scripts/rollback-db.sh <service> [revision]
#   revision defaults to "-1" (one step down)

set -euo pipefail

SERVICE="${1:-}"
REVISION="${2:--1}"

CYAN='\033[0;36m'; GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'

PYTHON_SERVICES=(ingestion crawler analytics user)

usage() {
    echo "Usage: ./scripts/rollback-db.sh <service> [revision]"
    echo "  service   : ${PYTHON_SERVICES[*]}"
    echo "  revision  : Alembic revision id or relative (-1, -2, …). Default: -1"
    exit 1
}

[[ -z "${SERVICE}" ]] && usage

# Validate service
valid=false
for svc in "${PYTHON_SERVICES[@]}"; do
    [[ "${svc}" == "${SERVICE}" ]] && valid=true && break
done
if [[ "${valid}" == "false" ]]; then
    printf "${RED}❌ '%s' has no Alembic migrations (or is not a Python service).${NC}\n" "${SERVICE}"
    usage
fi

SERVICE_DIR="services/${SERVICE}"

if [[ ! -f "${SERVICE_DIR}/alembic.ini" ]]; then
    printf "${RED}❌ No alembic.ini found in %s — skipping DB rollback.${NC}\n" "${SERVICE_DIR}"
    exit 0
fi

printf "${CYAN}🔄 Rolling back DB for '%s' to revision '%s'…${NC}\n" "${SERVICE}" "${REVISION}"

pushd "${SERVICE_DIR}" > /dev/null

# Activate venv if present
if [[ -d ".venv" ]]; then
    # shellcheck source=/dev/null
    source ".venv/bin/activate"
fi

alembic downgrade "${REVISION}"

echo "Current Alembic state after rollback:"
alembic current

popd > /dev/null

printf "${GREEN}✅ Database rollback complete for '%s'.${NC}\n" "${SERVICE}"
