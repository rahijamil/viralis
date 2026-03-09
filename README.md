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
- **DevOps**: Docker, GitHub Actions

## 🚦 Quick Start

### Prerequisites
- Docker & Docker Compose
- Python 3.11+ (for local scripting)

### Launching the Stack

1. **Clone the repository**:
   ```bash
   git clone https://github.com/rahijamil/viralis.git
   cd viralis
   ```

2. **Setup Environment**:
   ```bash
   cp .env.example .env
   ```

3. **Start the services**:
   ```bash
   docker-compose up -d --build
   ```

The database will automatically initialize and seed with test data. You can verify the services using `docker-compose ps`.

## 📂 Project Structure

- `docs/`: Project documentation and design specs.
- `infrastructure/`: Docker, Database migrations (`dbmate`), and infra configs.
- `scripts/`: Initialization and seeding scripts.
- `services/`: Microservice implementations.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
