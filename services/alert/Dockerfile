# --- Build Stage ---
FROM node:20-slim AS builder

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .

# --- Final Stage ---
FROM node:20-slim

WORKDIR /app

# Non-root user for security
RUN groupadd -r viralis && useradd --no-log-init -r -g viralis viralis

COPY --from=builder /app/node_modules ./node_modules
COPY . .

# Set correct permissions
RUN chown -R viralis:viralis /app

USER viralis

CMD ["node", "src/index.js"]
