# Viralis Makefile - Common Development Commands

.PHONY: help up down restart ps logs build test clean shell db-shell seed

# Default service for shell commands
service ?= user-service

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Targets:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

up: ## Start the Docker Compose stack in detached mode
	@echo "🚀 Starting services..."
	docker-compose up -d --build

down: ## Stop the Docker Compose stack
	@echo "🛑 Stopping services..."
	docker-compose down

restart: ## Restart all services
	@echo "🔄 Restarting services..."
	docker-compose restart

ps: ## View the status of all running services
	docker-compose ps

logs: ## View logs from all services (use service=name for specific logs)
	docker-compose logs -f $(service)

build: ## Build or rebuild services
	docker-compose build

test: ## Run all quality checks (pre-commit)
	@echo "🔍 Running quality checks..."
	source .venv/bin/activate && pre-commit run --all-files

clean: ## Remove containers, networks, and images
	@echo "🧹 Cleaning up Docker resources..."
	docker-compose down --rmi local --remove-orphans

shell: ## Open a bash shell in a service (defaults to user-service)
	docker-compose exec $(service) /bin/sh

db-shell: ## Open psql in the PostgreSQL container
	docker-compose exec postgres psql -U viralis -d viralis

seed: ## Record the database seeding process
	@echo "🌱 Seeding database..."
	docker-compose exec seeder python scripts/seed_data.py
