# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Viralis** is a distributed microservices platform for content ingestion and trend analysis across social networks. The system uses a microservices architecture with services written in Python, Go, and Node.js.

## Architecture

- **Services**: ingestion (Python), ingestion-go (Go), crawler (Python), analytics (Python), alert (Node.js), dashboard (Node.js), user (Python)
- **Infrastructure**: PostgreSQL, Redis, Kafka, Qdrant (vector database)
- **Deployment**: Docker Compose for local dev, Kubernetes manifests for production
- **Orchestration**: Docker Compose for local development

## Common Commands

### Local Development (Makefile)

- `make up` - Start the entire Docker stack in detached mode
- `make down` - Stop and remove containers
- `make ps` - Check service status
- `make logs [service=name]` - View real-time logs
- `make test` - Run all quality checks (pre-commit)
- `make build` - Rebuild all Docker images
- `make db-shell` - Access PostgreSQL interactive shell
- `make shell [service=<name>]` - Open bash shell in a service

### Service-Specific Tests

For Python services (ingestion, crawler, analytics, user):

```bash
cd services/<service-name>
python -m pytest
```

For Node services (alert, dashboard):

```bash
cd services/<service-name>
npm test
```

For Go service (ingestion-go):

```bash
cd services/ingestion-go
go test -race -cover ./...
```

### Pre-commit Hooks

```bash
source .venv/bin/activate
pre-commit run --all-files
```

## Service Structure

All services follow a similar structure:

```
services/<service-name>/
├── Dockerfile
├── requirements.txt (or package.json for Node)
├── src/
│   └── main.py (or index.js, main.go)
└── tests/
    └── test_main.py (or index.test.js, main_test.go)
```

**Key conventions:**

- Health endpoint at `/health`
- Services listen on port 8080
- Multi-stage Docker builds for Python services
- Environment variables via docker-compose or Kubernetes

## CI/CD Workflows

### PR Validation (`.github/workflows/pr-validation.yml`)

- Runs on pull requests to `main`
- Parallel testing: Python, Go, Node.js services
- Path filtering: only tests services that changed
- Security scanning: `safety`, `npm audit`, `nancy`
- Docker linting with hadolint

### Docker Build (`.github/workflows/docker-build.yml`)

- Runs on merge to `main` or release tags
- Multi-arch builds (amd64, arm64)
- Pushes to Docker Hub
- Trivy vulnerability scanning

## Environment Configuration

Copy `.env.example` to `.env` for local development. Defaults work with docker-compose setup.

## Database Migrations

Uses `dbmate` for PostgreSQL migrations. Migrations are located in `infrastructure/postgres/migrations/`. The migration service runs automatically on `docker-compose up`.

## Key Files

- `Makefile` - Development commands
- `docker-compose.yml` - Local infrastructure setup
- `.pre-commit-config.yaml` - Code quality hooks
- `k8s/*.yaml` - Kubernetes deployment manifests
- `scripts/` - Utility scripts (rollback, validation, etc.)
