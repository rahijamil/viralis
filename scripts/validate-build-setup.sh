#!/bin/bash

# Viralis Build Setup Validator

set -e

RED='\033[0-31m'
GREEN='\033[0-32m'
YELLOW='\033[0-33m'
NC='\033[0m'

echo -e "${YELLOW}==============================================${NC}"
echo -e "${YELLOW}   Viralis Docker Build Setup Validator      ${NC}"
echo -e "${YELLOW}==============================================${NC}"
echo ""

# Check Docker Hub Secrets (Requires GH CLI)
echo -e "Checking GitHub Secrets..."
if command -v gh &> /dev/null; then
    for secret in DOCKERHUB_USERNAME DOCKERHUB_TOKEN; do
        if gh secret list | grep -q "$secret"; then
            echo -e "  ${GREEN}✅ $secret configured${NC}"
        else
            echo -e "  ${RED}❌ $secret missing${NC}"
        fi
    done
else
    echo -e "  ${YELLOW}⚠️ gh cli not found, skipping secret check${NC}"
fi

# Check workflow file exists
echo -n "Checking workflow file... "
if [ -f .github/workflows/docker-build.yml ]; then
    echo -e "${GREEN}✅${NC}"
else
    echo -e "${RED}❌ Missing .github/workflows/docker-build.yml${NC}"
fi

# Check Dockerfiles
echo "Checking Dockerfiles:"
for service in ingestion ingestion-go crawler analytics alert user dashboard; do
    if [ -f "services/$service/Dockerfile" ]; then
        echo -e "  ${GREEN}✅ services/$service/Dockerfile${NC}"
    else
        echo -e "  ${RED}❌ services/$service/Dockerfile missing${NC}"
    fi
done

# Check multi-arch buildx
echo -n "Checking multi-arch support... "
if docker buildx ls | grep -q "linux/arm64.*linux/amd64"; then
    echo -e "${GREEN}✅${NC}"
else
    echo -e "${RED}❌ Multi-arch not fully configured${NC}"
    echo -e "   Run: ${YELLOW}docker buildx create --name multiarch --use${NC}"
    echo -e "   Run: ${YELLOW}docker buildx inspect --bootstrap${NC}"
fi

echo ""
echo -e "${YELLOW}==============================================${NC}"
echo "To test the workflow:"
echo "1. Create a PR: gh pr create --title 'Test Docker' --body 'Testing'"
echo "2. Check workflow: gh run list"
echo -e "${YELLOW}==============================================${NC}"
echo -e "${GREEN}✅ Validation complete${NC}"
