# Build stage
FROM golang:1.21-alpine AS builder
WORKDIR /app
COPY go.mod go.su[m] ./
RUN go mod download
COPY . .
RUN go build -o ingestion-service ./cmd/app/main.go

# Runtime stage
FROM alpine:3.19
RUN apk --no-cache add ca-certificates=20240203-r0
WORKDIR /root/

# Create non-root user
RUN addgroup -g 1000 -S appuser && adduser -u 1000 -S appuser -G appuser
USER appuser

COPY --from=builder /app/ingestion-service .

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD ["./ingestion-service", "health"]

LABEL org.opencontainers.image.source="https://github.com/rahijamil/viralis"
LABEL org.opencontainers.image.description="Viralis ingestion-go service"
LABEL maintainer="rahijamil"

EXPOSE 8080
CMD ["./ingestion-service"]
