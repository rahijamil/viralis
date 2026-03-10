# Pull Request Validation Guide

This document explains the automated validation process for pull requests in the Viralis project.

## 🏗️ Workflow Overview

Every PR targeting the `main` branch triggers the **PR Validation** workflow. This workflow ensures that all microservices remain healthy, secure, and compliant with out standards.

### 🔍 Automated Checks

| Check                  | Tools Used                           | Description                                                                                    |
| :--------------------- | :----------------------------------- | :--------------------------------------------------------------------------------------------- |
| **Python Validation**  | `pytest`, `flake8`, `mypy`, `bandit` | Runs unit tests, linting, type-checking, and security scans for changed Python services.       |
| **Go Validation**      | `go test`, `golangci-lint`           | Runs tests with race detection and comprehensive linting for Go services.                      |
| **Node.js Validation** | `jest`, `eslint`, `prettier`, `tsc`  | Validates JavaScript/TypeScript code in the Dashboard and Alert services.                      |
| **Docker Validation**  | `hadolint`, `docker build`           | Lints Dockerfiles and ensures images build successfully.                                       |
| **Security Scanning**  | `safety`, `npm audit`, `nancy`       | Scans dependencies for known vulnerabilities across all ecosystems.                            |
| **Quality Gates**      | Custom Scripts                       | Enforces conventional PR titles (e.g., `feat:`, `fix:`) and ensures the PR template is filled. |

## 🛠️ Local Development

To catch issues before pushing, we use `pre-commit` hooks. These hooks run a subset of the CI checks locally.

### Running All Checks Locally

```bash
source .venv/bin/activate
pre-commit run --all-files
```

## ❓ FAQ

### 1. Why did my service job skip?

We use **Path Filtering**. If you didn't change any files in a specific service's directory, its validation job will be skipped to save time and resources.

### 2. How do I bypass a failing check?

Status checks are **required** for merging. If a check is failing incorrectly, please coordinate with the team to fix the underlying issue or the CI configuration.

### 3. How do I add a new service?

Update the filters in `.github/workflows/pr-validation.yml` and ensure your service has the standard test/lint configuration files.
