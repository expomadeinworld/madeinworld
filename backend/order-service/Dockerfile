# Multi-stage build for Go application
# Stage 1: Build the application
FROM golang:1.23-alpine AS builder

# Set working directory
WORKDIR /app

# Install git and ca-certificates (needed for go mod download)
RUN apk add --no-cache git ca-certificates

# Copy go mod files
COPY go.mod go.sum ./

# Download dependencies
RUN go mod download

# Copy source code
COPY . .

# Build the application
# CGO_ENABLED=0 creates a static binary
# GOOS=linux ensures Linux compatibility
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o order-service ./cmd/server

# Stage 2: Create the final image
FROM alpine:latest

# Install ca-certificates for HTTPS requests
RUN apk --no-cache add ca-certificates

# Create a non-root user
RUN addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup

# Set working directory
WORKDIR /app

# Copy the binary from builder stage
COPY --from=builder /app/order-service .

# Change ownership to non-root user
RUN chown appuser:appgroup /app/order-service

# Switch to non-root user
USER appuser

# Expose port 8082
EXPOSE 8082

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8082/health || exit 1

# Run the application
CMD ["./order-service"]
