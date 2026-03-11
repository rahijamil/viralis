"""Analytics service entry point."""

import os

import uvicorn
from fastapi import FastAPI

app = FastAPI(title="Viralis Analytics Service")


@app.get("/health")
def health():
    """Health check endpoint."""
    return {"status": "healthy", "service": "analytics"}


@app.get("/stats")
def stats():
    """Get statistics endpoint."""
    return {"status": "ok", "stats": {"active_users": 100, "processed_events": 5000}}


def main() -> None:
    """Run the analytics service loop."""
    port = int(os.environ.get("PORT", 8080))
    print(f"🚀 Analytics Service starting on port {port}...")
    uvicorn.run(app, host="0.0.0.0", port=port)  # nosec B104


if __name__ == "__main__":
    main()
