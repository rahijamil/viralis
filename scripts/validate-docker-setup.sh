#!/bin/bash
# scripts/validate-docker-setup.sh

echo "🔍 Validating Docker automated builds setup..."
echo "=============================================="

# Check GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI not installed"
    exit 1
fi

# Check Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker not installed"
    exit 1
fi

# Check Docker Hub login
echo -n "Checking Docker Hub login... "
if docker pull rahijamil/hello-world &> /dev/null; then
    echo "✅"
else
    # Try a common public image as fallback check for basic connectivity
    if docker pull hello-world &> /dev/null; then
        echo "✅ (Public connectivity ok)"
    else
        echo "❌ Cannot access Docker Hub. Run 'docker login' first."
    fi
fi

# Check GitHub secrets
echo "Checking GitHub secrets:"
for secret in DOCKERHUB_USERNAME DOCKERHUB_TOKEN; do
    if gh secret list | grep -q $secret; then
        echo "  ✅ $secret configured"
    else
        echo "  ❌ $secret missing"
    fi
done

# Check workflow file exists
echo -n "Checking workflow file... "
if [ -f .github/workflows/docker-build.yml ]; then
    echo "✅"
else
    echo "❌ Missing .github/workflows/docker-build.yml"
fi

# Check Dockerfiles
echo "Checking Dockerfiles:"
for service in ingestion crawler analytics alert user; do
    if [ -f "services/$service/Dockerfile" ]; then
        echo "  ✅ services/$service/Dockerfile"
    else
        echo "  ❌ services/$service/Dockerfile missing"
    fi
done

if [ -f "services/dashboard/Dockerfile" ]; then
    echo "  ✅ services/dashboard/Dockerfile"
else
    echo "  ❌ services/dashboard/Dockerfile missing"
fi

if [ -f "services/ingestion-go/Dockerfile" ]; then
    echo "  ✅ services/ingestion-go/Dockerfile"
else
    echo "  ❌ services/ingestion-go/Dockerfile missing"
fi

# Check multi-arch buildx
echo -n "Checking multi-arch support... "
if docker buildx ls | grep -q "linux/arm64.*linux/amd64"; then
    echo "✅"
else
    echo "❌ Multi-arch not fully configured"
    echo "   Run: docker buildx create --name multiarch --use"
    echo "   Run: docker buildx inspect --bootstrap"
fi

echo ""
echo "=============================================="
echo "To test the workflow:"
echo "1. Create a PR: gh pr create --title 'Test Docker' --body 'Testing'"
echo "2. Check workflow: gh run list"
echo "3. Verify images: docker pull rahijamil/viralis-ingestion:pr-{number}-{sha}"
echo ""
echo "✅ Validation complete"
