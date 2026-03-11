# --- Build Stage ---
FROM python:3.11-slim as builder

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# hadolint ignore=DL3008
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN mkdir -p /install && \
    pip install --no-cache-dir --prefix=/install -r requirements.txt

# --- Final Stage ---
FROM python:3.11-slim

WORKDIR /app

# Non-root user for security
RUN groupadd -r viralis && useradd --no-log-init -r -g viralis viralis

COPY --from=builder /install /usr/local
COPY . .

# Set correct permissions
RUN chown -R viralis:viralis /app

USER viralis

CMD ["python", "src/main.py"]
