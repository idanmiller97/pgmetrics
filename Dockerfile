# ┌─── build stage ───────────────────────────────────────────────────────┐
FROM golang:1.23 AS builder
WORKDIR /app

# only grab module definitions first
COPY go.mod go.sum ./
RUN go mod download

# copy exactly the library and cmd tree—ignore any example_usage.go you might have
COPY model.go ./
COPY collector ./collector
COPY cmd/pgmetrics ./cmd/pgmetrics

# build a static Linux binary
RUN CGO_ENABLED=0 GOOS=linux \
    go build -ldflags="-s -w" -o pgmetrics ./cmd/pgmetrics
# └────────────────────────────────────────────────────────────────────────┘

# ┌─── final image ───────────────────────────────────────────────────────┐
FROM alpine:latest
RUN apk add --no-cache ca-certificates

COPY --from=builder /app/pgmetrics /usr/local/bin/pgmetrics
ENTRYPOINT ["pgmetrics"]
CMD ["--help"]
# └────────────────────────────────────────────────────────────────────────┘