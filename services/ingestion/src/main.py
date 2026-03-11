"""Ingestion service entry point."""

import os

import uvicorn
from fastapi import FastAPI

app = FastAPI(title="Viralis Ingestion Service")


@app.get("/health")
def health():
    """Health check endpoint."""
    return {"status": "healthy", "service": "ingestion"}


@app.post("/ingest")
def ingest(data: dict):
    """Ingest data endpoint."""
    # Dummy logic for ingestion
    return {"status": "accepted", "source": data.get("source", "unknown")}


def main() -> None:
    """Run the ingestion service loop."""
    port = int(os.environ.get("PORT", 8080))
    print(f"🚀 Ingestion Service starting on port {port}...")
    uvicorn.run(app, host="0.0.0.0", port=port)  # nosec B104


if __name__ == "__main__":
    main()
