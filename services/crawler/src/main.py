"""Crawler service entry point."""

import os

import uvicorn
from fastapi import FastAPI

app = FastAPI(title="Viralis Crawler Service")


@app.get("/health")
def health():
    """Health check endpoint."""
    return {"status": "healthy", "service": "crawler"}


@app.post("/crawl")
def crawl(url: str):
    """Crawl URL endpoint."""
    if not url.startswith("http"):
        return {"status": "error", "message": "Invalid URL"}
    return {"status": "crawling", "url": url}


def main() -> None:
    """Run the crawler service loop."""
    port = int(os.environ.get("PORT", 8080))
    print(f"🚀 Crawler Service starting on port {port}...")
    uvicorn.run(app, host="0.0.0.0", port=port)  # nosec B104


if __name__ == "__main__":
    main()
