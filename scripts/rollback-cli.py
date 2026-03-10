#!/usr/bin/env python3
"""Viralis rollback CLI — wrapper around rollback.sh and track-rollback.py."""

import subprocess
import sys
from pathlib import Path

import click

SCRIPT_DIR = Path(__file__).parent
ROLLBACK_SH = SCRIPT_DIR / "rollback.sh"

SERVICES = ["ingestion", "ingestion-go", "crawler", "analytics", "alert", "user", "dashboard"]


def _run(cmd: list[str]) -> int:
    """Run a shell command and return the exit code."""
    result = subprocess.run(cmd)  # noqa: S603
    return result.returncode


# ─── CLI group ────────────────────────────────────────────────────────────────
@click.group()
def cli() -> None:
    """Viralis rollback automation CLI."""


# ─── rollback ─────────────────────────────────────────────────────────────────
@cli.command()
@click.argument("service", type=click.Choice(SERVICES, case_sensitive=False))
@click.option("--to", "target", default=None, help="Image tag to roll back to")
@click.option("--namespace", default="production", show_default=True)
@click.option("--dry-run", is_flag=True, help="Simulate without applying changes")
def rollback(service: str, target: str | None, namespace: str, dry_run: bool) -> None:
    """Roll back a single SERVICE to the previous (or specified) version."""
    cmd = ["bash", str(ROLLBACK_SH), service, "--namespace", namespace]
    if target:
        cmd += ["--to", target]
    if dry_run:
        cmd.append("--dry-run")

    click.echo(f"🔄 Rolling back {service!r}…")
    rc = _run(cmd)
    if rc == 0:
        click.secho("✅ Rollback complete.", fg="green")
    else:
        click.secho(f"❌ Rollback failed (exit {rc}).", fg="red")
        sys.exit(rc)


# ─── rollback-all ─────────────────────────────────────────────────────────────
@cli.command("rollback-all")
@click.option("--to", "target", default=None, help="Image tag to roll back to")
@click.option("--namespace", default="production", show_default=True)
@click.option("--dry-run", is_flag=True)
def rollback_all(target: str | None, namespace: str, dry_run: bool) -> None:
    """Roll back ALL services."""
    cmd = ["bash", str(ROLLBACK_SH), "--all", "--namespace", namespace]
    if target:
        cmd += ["--to", target]
    if dry_run:
        cmd.append("--dry-run")

    click.echo("🔄 Rolling back ALL services…")
    rc = _run(cmd)
    if rc == 0:
        click.secho("✅ All services rolled back.", fg="green")
    else:
        click.secho(f"❌ Some rollbacks failed (exit {rc}).", fg="red")
        sys.exit(rc)


# ─── status ───────────────────────────────────────────────────────────────────
@cli.command()
@click.option("--namespace", default="production", show_default=True)
def status(namespace: str) -> None:
    """Show current deployment status for all services."""
    click.echo(f"📊 Deployment status (namespace: {namespace})\n")

    rows = []
    for svc in SERVICES:
        deployment = svc if svc == "dashboard" else f"{svc}-service"
        # Current image
        img_cmd = [
            "kubectl",
            "get",
            "deployment",
            deployment,
            "-n",
            namespace,
            "-o",
            "jsonpath={.spec.template.spec.containers[0].image}",
        ]
        img_res = subprocess.run(img_cmd, capture_output=True, text=True)
        image = img_res.stdout.strip() or "not deployed"
        tag = image.split(":")[-1] if ":" in image else image

        # Ready pods
        pods_cmd = [
            "kubectl",
            "get",
            "deployment",
            deployment,
            "-n",
            namespace,
            "-o",
            "jsonpath={.status.readyReplicas}/{.spec.replicas}",
        ]
        pods_res = subprocess.run(pods_cmd, capture_output=True, text=True)
        pods = pods_res.stdout.strip() or "—"

        health = "✅" if img_res.returncode == 0 and image != "not deployed" else "⚠️"
        rows.append((health, svc, tag[:30], pods))

    # Print table
    header = f"  {'':3} {'Service':<15} {'Image Tag':<32} {'Pods'}"
    click.echo(header)
    click.echo("  " + "-" * (len(header) - 2))
    for health, svc, tag, pods in rows:
        click.echo(f"  {health}  {svc:<15} {tag:<32} {pods}")


# ─── history ──────────────────────────────────────────────────────────────────
@cli.command()
@click.argument("service", required=False, default=None)
@click.option("--limit", default=20, show_default=True)
def history(service: str | None, limit: int) -> None:
    """Display recent rollback events, optionally filtered by a service name."""
    sys.path.insert(0, str(SCRIPT_DIR))
    from track_rollback import get_history  # noqa: PLC0415,E402

    rows = get_history(service, limit)
    if not rows:
        click.echo("No rollback history found.")
        return

    col = "{'ID':<4} {'Timestamp':<22} {'Service':<14} {'From':<22}"
    header = f"{col} {'To':<22} {'Trigger':<18} Status"
    click.echo(header)
    click.echo("-" * len(header))
    for row in rows:
        rid, ts, svc, frm, to, trig, stat = (
            row[0],
            row[1][:19],
            row[2],
            row[3][:20],
            row[4][:20],
            row[5],
            row[6],
        )
        colour = "green" if stat == "success" else "red"
        line = f"{rid:<4} {ts:<22} {svc:<14} {frm:<22} {to:<22} {trig:<18}"
        click.echo(line, nl=False)
        click.secho(f" {stat}", fg=colour)


if __name__ == "__main__":
    cli()
