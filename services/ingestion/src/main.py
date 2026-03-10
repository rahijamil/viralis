"""Ingestion service entry point."""

import os
import time


def main() -> None:
    """Run the ingestion service loop."""
    print(f"🚀 {os.environ.get('SERVICE_NAME', 'Service')} starting...")
    while True:
        time.sleep(3600)


if __name__ == "__main__":
    main()
