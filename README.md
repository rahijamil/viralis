# Viralis

**Viralis** is a high-performance content ingestion and trend analysis platform designed to identify viral opportunities across multiple social networks in real-time.

## 🚀 Overview

Viralis uses a distributed microservices architecture to crawl, ingest, and analyze social media trends. It leverages vector databases for similarity search and LLMs for content summarization, providing actionable insights for growth hackers and content creators.

## 🏗 Architecture

The system is composed of several key components:

- **Ingestion Engine**: Real-time data collection from various APIs.
- **Analytics Service**: Trend detection and sentiment analysis using AI.
- **Alert System**: Multi-channel notifications for detected high-velocity trends.
- **Vector Search**: Powered by **Qdrant** for deep content analysis.
- **Orchestration**: Managed via **Docker Compose** for seamless local development.

## 🛠 Tech Stack

- **Languages**: Python, Go
- **Infrastructure**: PostgreSQL, Redis, Kafka, Qdrant
- **DevOps**: Docker, GitHub Actions, `dbmate` (Migrations)
- **CI/CD**: Automated Multi-arch Docker builds (amd64/arm64) with Trivy security scanning.

## 📋 Prerequisites

Ensure you have the following installed before starting:

- **Docker & Docker Compose**: (e.g., Docker Desktop or OrbStack)
- **Git**: For version control.
- **Python 3.11+**: For local scripts and development tools.
- **Go 1.21+**: (Optional) Required for local Go service development.
- **Node.js 20+**: (Optional) Required for local Dashboard development.

## 🚦 Local Development Setup

Follow these steps to get your environment running in under 30 minutes:

### 1. Clone the Repository

```bash
git clone https://github.com/rahijamil/viralis.git
cd viralis
```

### 2. Configure Environment Variables

Copy the example environment file and adjust values as needed (defaults work for local Docker setup):

```bash
cp .env.example .env
```

### 3. Initialize Developer Tools

Install the `pre-commit` hooks and set up the root virtual environment:

```bash
./scripts/install-hooks.sh
```

### 4. Launch the Infrastructure

Start the database, message broker, and vector store:

```bash
docker-compose up -d --build
```

_The database will auto-migrate and seed with test data on the first run._

## 🛠 Developer Commands (Makefile)

To simplify your workflow, we use a `Makefile`. Run `make help` to see all available commands.

| Command         | Description                                    |
| :-------------- | :--------------------------------------------- |
| `make up`       | Start the entire stack in detached mode.       |
| `make down`     | Stop and remove the containers.                |
| `make ps`       | Check the status of running services.          |
| `make logs`     | View real-time logs (supports `service=name`). |
| `make test`     | Run all linting and quality checks.            |
| `make db-shell` | Access the PostgreSQL interactive shell.       |
| `make seed`     | Manually trigger database seeding.             |
| `make build`    | Build all Docker images locally.               |

| `make build` | Build all Docker images locally. |

## 🚀 CI/CD Pipeline

We use GitHub Actions for automated quality assurance and deployment:

### 1. PR Validation (`pr-validation.yml`)

Runs on every pull request to `main`:

- **Parallel Testing**: Matrix strategy to validate Python, Go, and Node.js services independently.
- **Path Filtering**: Only tests services that have changed in the PR.
- **Security Scanning**: Scans dependencies for vulnerabilities (`safety`, `npm audit`, `nancy`).
- **Quality Gates**: Enforces conventional PR titles and template completion.

### 2. Docker Build (`docker-build.yml`)

Runs on merge to `main` or release tags:

- Builds and pushes multi-arch (`amd64`, `arm64`) images to Docker Hub.
- Per-service vulnerability scanning with **Trivy**.

### Validate Build Setup

Run this script to verify your local environment and GitHub secrets:

```bash
./scripts/validate-build-setup.sh
```

```bash
./scripts/validate-build-setup.sh
```

## 🧪 Running Tests

### Automation Checks

Run all linting and security checks manually at anytime:

```bash
source .venv/bin/activate
pre-commit run --all-files
```

### Service Tests

_Note: Service-specific test suites are currently being implemented._
To run Python service tests:

```bash
cd services/<service-name>
python -m pytest
```

## 📚 API Documentation

Once the services are running, you can access the interactive API documentation at:

- **User Service**: [http://localhost:8080/docs](http://localhost:8080/docs) (Placeholder)
- **Ingestion Service**: [http://localhost:8081/docs](http://localhost:8081/docs) (Placeholder)

## 🔍 Troubleshooting

| Issue                           | Solution                                                              |
| :------------------------------ | :-------------------------------------------------------------------- |
| **Docker containers failing**   | Check logs with `docker-compose logs <service_name>`.                 |
| **Database connection refused** | Ensure the `migration` container finished successfully.               |
| **Kafka startup issues**        | Ensure you have at least 4GB of RAM allocated to Docker.              |
| **Pre-commit hooks failing**    | Ensure you have activated the root venv: `source .venv/bin/activate`. |

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on how to get started, our branching model, and code standards.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
