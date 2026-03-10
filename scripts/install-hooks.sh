#!/bin/bash
# Install pre-commit hooks for all developers

echo "🚀 Setting up development environment for Viralis..."

# 1. Ensure a root virtual environment exists
if [ ! -d ".venv" ]; then
    echo "📦 Creating root virtual environment..."
    python3 -m venv .venv
fi

# 2. Activate root venv and install dev dependencies
echo "📦 Installing global development tools..."
source .venv/bin/activate
pip install -r requirements-dev.txt

# 3. Install the hooks
echo "⚓ Installing git hooks..."
pre-commit install --hook-type pre-commit
pre-commit install --hook-type pre-push

echo ""
echo "✅ Development environment ready!"
echo "--------------------------------------------------------"
echo "💡 VIRTUAL ENVIRONMENT STRATEGY:"
echo "1. ROOT VENV (.venv/): Used for global tools like pre-commit and detect-secrets."
echo "2. SERVICE VENVS (services/*/venv/): Use separate ones for each microservice to avoid version conflicts."
echo "--------------------------------------------------------"
echo "🔍 To run quality checks manually: source .venv/bin/activate && pre-commit run --all-files"
