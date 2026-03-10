# --- Build Stage ---
FROM golang:1.21-alpine AS builder

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o /viralis-ingestion ./cmd/app/main.go

# --- Final Stage ---
FROM alpine:3.18

WORKDIR /app

# Non-root user for security
RUN addgroup -S viralis && adduser -S viralis -G viralis

COPY --from=builder /viralis-ingestion .

# Set correct permissions
RUN chown -R viralis:viralis /app

USER viralis

CMD ["./viralis-ingestion"]
