FROM node:20-slim AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

FROM node:20-slim AS runtime
WORKDIR /app

# Create non-root user
RUN useradd --create-home appuser
USER appuser

# Copy node_modules from builder
COPY --from=builder --chown=appuser:appuser /app/node_modules ./node_modules
COPY --chown=appuser:appuser src/ ./src/
COPY --chown=appuser:appuser package*.json ./

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:8080/health', (r) => r.statusCode === 200 ? process.exit(0) : process.exit(1))"

LABEL org.opencontainers.image.source="https://github.com/rahijamil/viralis"
LABEL org.opencontainers.image.description="Alert service for Viralis"
LABEL maintainer="rahijamil"

EXPOSE 8080
CMD ["node", "src/index.js"]
