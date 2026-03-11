# Multi-stage build for Python service
FROM python:3.11-slim AS builder

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

FROM python:3.11-slim AS runtime
WORKDIR /app

# Create non-root user
RUN useradd --create-home appuser
USER appuser

# Copy dependencies from builder
COPY --from=builder --chown=appuser:appuser /root/.local /home/appuser/.local
ENV PATH=/home/appuser/.local/bin:$PATH
ENV PYTHONUNBUFFERED=1

# Copy application code
COPY --chown=appuser:appuser src/ ./src/
COPY --chown=appuser:appuser requirements.txt .

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD python -c "import requests; requests.get('http://localhost:8080/health')" || exit 1

# Metadata
LABEL org.opencontainers.image.source="https://github.com/rahijamil/viralis"
LABEL org.opencontainers.image.description="Viralis crawler service"
LABEL org.opencontainers.image.licenses="MIT"
LABEL maintainer="rahijamil"

EXPOSE 8080
CMD ["python", "src/main.py"]
