# Build stage for React frontend
FROM node:20-slim AS frontend-builder
WORKDIR /app/client
COPY client/package*.json ./
RUN npm install
COPY client/ ./
RUN npm run build

# Build stage for Node.js backend
FROM node:20-slim AS backend-builder
WORKDIR /app
COPY package*.json ./
RUN npm install --production

# Runtime stage
FROM node:20-slim
WORKDIR /app

# Create non-root user
RUN useradd --create-home appuser
USER appuser

# Copy backend dependencies
COPY --from=backend-builder --chown=appuser:appuser /app/node_modules ./node_modules
# Copy backend source
COPY --chown=appuser:appuser src/ ./src/
COPY --chown=appuser:appuser package*.json ./
# Copy frontend build
COPY --from=frontend-builder --chown=appuser:appuser /app/client/dist ./client/dist

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:8080/health', (r) => r.statusCode === 200 ? process.exit(0) : process.exit(1))"

LABEL org.opencontainers.image.source="https://github.com/rahijamil/viralis"
LABEL org.opencontainers.image.description="Dashboard service for Viralis (Node/React)"
LABEL org.opencontainers.image.licenses="MIT"
LABEL maintainer="rahijamil"

EXPOSE 8080
CMD ["node", "src/index.js"]
