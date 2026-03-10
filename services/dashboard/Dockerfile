# --- Build Stage ---
FROM node:20-alpine AS builder

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .

# --- Final Stage ---
FROM node:20-alpine

WORKDIR /app

RUN addgroup -S viralis && adduser -S viralis -G viralis

COPY --from=builder /app/node_modules ./node_modules
COPY . .

USER viralis

CMD ["npm", "start"]
