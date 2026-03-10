# Rollback Runbook — On-Call Guide

This runbook is the primary reference for engineers who need to perform rollbacks in the Viralis production environment.

## 🚨 Quick Reference

| Scenario                   | Command                                             |
| :------------------------- | :-------------------------------------------------- |
| Single service failing     | `./scripts/rollback.sh <service>`                   |
| Multiple services failing  | `./scripts/rollback.sh --all`                       |
| Roll back to specific tag  | `./scripts/rollback.sh <service> --to main-a1b2c3d` |
| Dry run (see what happens) | `./scripts/rollback.sh --dry-run --all`             |
| Database rollback          | `./scripts/rollback-db.sh <service>`                |
| View rollback history      | `python3 scripts/track-rollback.py history`         |

## 📋 Rollback Decision Tree

```
Service is degraded
       ↓
Is it a deployment issue?
  ├─ YES → Run: ./scripts/rollback.sh <service>
  │         Wait 2 minutes for completion
  │         Smoke tests run automatically
  │         → If stable: done ✅
  │         → If still degraded: rollback-db.sh + escalate
  └─ NO  → Check infrastructure (DB, Kafka, Redis)
           Check dependencies with: ./scripts/check-health.sh
```

## 🔄 Manual Rollback Steps

### Step 1: Identify the failing service

```bash
python3 scripts/rollback-cli.py status
```

### Step 2: Rollback

```bash
# Single service
./scripts/rollback.sh ingestion

# All services
./scripts/rollback.sh --all
```

### Step 3: Verify

Smoke tests run automatically. You can also verify manually:

```bash
kubectl rollout status deployment/ingestion-service -n production
kubectl get pods -n production
```

## 🗄️ Database Rollback

Only run if the rollback also requires reverting a DB migration:

```bash
# Downgrade 1 migration step
./scripts/rollback-db.sh ingestion

# Downgrade to a specific revision
./scripts/rollback-db.sh ingestion <alembic-revision-id>
```

> [!CAUTION]
> Always confirm migrations are backward-compatible before rolling back. Never run DB rollback if new data has been written with the new schema without a data migration plan.

## 🆘 Disaster Recovery

If the entire stack is unhealthy:

```bash
# 1. Roll back all services
./scripts/rollback.sh --all

# 2. Check status
python3 scripts/rollback-cli.py status

# 3. Run health check
./scripts/check-health.sh

# 4. View recent rollbacks
python3 scripts/track-rollback.py history --limit 10
```

## 📊 Rollback History

All rollback events are stored in `data/rollback_history.db`.

```bash
# All events
python3 scripts/track-rollback.py history

# Single service
python3 scripts/track-rollback.py history ingestion --limit 5
```

## ☸️ Raw Kubectl Commands

If scripts are unavailable:

```bash
# View deployment history
kubectl rollout history deployment/ingestion-service -n production

# Roll back to previous revision
kubectl rollout undo deployment/ingestion-service -n production

# Roll back to specific revision
kubectl rollout undo deployment/ingestion-service --to-revision=3 -n production

# Watch status
kubectl rollout status deployment/ingestion-service -n production -w
```
