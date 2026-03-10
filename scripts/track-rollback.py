#!/usr/bin/env python3
"""Track rollback history in a local SQLite database for audit purposes.

Usage (CLI):
    python3 scripts/track-rollback.py track <service> <from> <to> <trigger> <status>
    python3 scripts/track-rollback.py history [service] [--limit N]
    python3 scripts/track-rollback.py clear
"""

import argparse
import json
import os
import sqlite3
from datetime import datetime, timezone

DB_DIR = os.path.join(os.path.dirname(__file__), "..", "data")
DB_PATH = os.path.join(DB_DIR, "rollback_history.db")


def _conn() -> sqlite3.Connection:
    os.makedirs(DB_DIR, exist_ok=True)
    return sqlite3.connect(DB_PATH)


def init_db() -> None:
    """Create the rollbacks table if it doesn't exist."""
    with _conn() as con:
        con.execute(
            """
            CREATE TABLE IF NOT EXISTS rollbacks (
                id               INTEGER PRIMARY KEY AUTOINCREMENT,
                timestamp        TEXT    NOT NULL,
                service          TEXT    NOT NULL,
                from_version     TEXT    NOT NULL,
                to_version       TEXT    NOT NULL,
                trigger          TEXT    NOT NULL,
                status           TEXT    NOT NULL,
                duration_seconds INTEGER,
                error            TEXT,
                metadata         TEXT
            )
            """
        )


def track_rollback(
    service: str,
    from_version: str,
    to_version: str,
    trigger: str,
    status: str,
    duration: int | None = None,
    error: str | None = None,
    metadata: dict | None = None,
) -> None:
    """Insert a rollback event into the history database."""
    init_db()
    with _conn() as con:
        con.execute(
            """
            INSERT INTO rollbacks
              (timestamp, service, from_version, to_version,
               trigger, status, duration_seconds, error, metadata)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                datetime.now(tz=timezone.utc).isoformat(),
                service,
                from_version,
                to_version,
                trigger,
                status,
                duration,
                error,
                json.dumps(metadata) if metadata else None,
            ),
        )


def get_history(service: str | None = None, limit: int = 50) -> list:
    """Return recent rollback events, optionally filtered by service."""
    init_db()
    with _conn() as con:
        if service:
            rows = con.execute(
                "SELECT * FROM rollbacks WHERE service = ?" " ORDER BY timestamp DESC LIMIT ?",
                (service, limit),
            ).fetchall()
        else:
            rows = con.execute(
                "SELECT * FROM rollbacks ORDER BY timestamp DESC LIMIT ?",
                (limit,),
            ).fetchall()
    return rows


def clear_history() -> None:
    """Delete all rollback history (useful for testing)."""
    init_db()
    with _conn() as con:
        con.execute("DELETE FROM rollbacks")
    print("Rollback history cleared.")


def _print_history(rows: list) -> None:
    """Print rollback history rows in a table format."""
    if not rows:
        print("No rollback history found.")
        return
    col = "{'ID':<4} {'Timestamp':<22} {'Service':<14} {'From':<22}"
    header = f"{col} {'To':<22} {'Trigger':<18} {'Status'}"
    print(header)
    print("-" * len(header))
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
        print(f"{rid:<4} {ts:<22} {svc:<14} {frm:<22} {to:<22} {trig:<18} {stat}")


def main() -> None:
    """Entry point for the rollback history CLI."""
    parser = argparse.ArgumentParser(description="Viralis rollback history tracker")
    sub = parser.add_subparsers(dest="command")

    # track
    p_track = sub.add_parser("track", help="Record a rollback event")
    p_track.add_argument("service")
    p_track.add_argument("from_version")
    p_track.add_argument("to_version")
    p_track.add_argument("trigger")
    p_track.add_argument("status")
    p_track.add_argument("--duration", type=int, default=None)
    p_track.add_argument("--error", default=None)

    # history
    p_hist = sub.add_parser("history", help="Show rollback history")
    p_hist.add_argument("service", nargs="?", default=None)
    p_hist.add_argument("--limit", type=int, default=50)

    # clear
    sub.add_parser("clear", help="Clear all history")

    args = parser.parse_args()

    if args.command == "track":
        track_rollback(
            service=args.service,
            from_version=args.from_version,
            to_version=args.to_version,
            trigger=args.trigger,
            status=args.status,
            duration=args.duration,
            error=args.error,
        )
        print(f"Tracked: {args.service} → {args.status}")
    elif args.command == "history":
        rows = get_history(args.service, args.limit)
        _print_history(rows)
    elif args.command == "clear":
        clear_history()
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
