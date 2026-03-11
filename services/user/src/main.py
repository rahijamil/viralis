"""User service entry point."""

import os

import uvicorn
from fastapi import FastAPI

app = FastAPI(title="Viralis User Service")


@app.get("/health")
def health():
    """Health check endpoint."""
    return {"status": "healthy", "service": "user"}


@app.get("/users/{user_id}")
def get_user(user_id: str):
    """Get user endpoint."""
    return {"user_id": user_id, "username": f"user_{user_id}", "active": True}


def main() -> None:
    """Run the user service loop."""
    port = int(os.environ.get("PORT", 8080))
    print(f"🚀 User Service starting on port {port}...")
    uvicorn.run(app, host="0.0.0.0", port=port)  # nosec B104


if __name__ == "__main__":
    main()
