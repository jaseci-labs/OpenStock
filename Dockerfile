# Build: neojac compiles the server and bundles the pages into one self-contained directory.
FROM debian:bookworm-slim AS build
RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates tar && rm -rf /var/lib/apt/lists/*
ENV NEOJAC_TELEMETRY=off PATH=/root/.local/bin:$PATH
RUN curl -fsSL https://github.com/jaseci-labs/neojac/releases/latest/download/install.sh | bash -s -- --version 0.5.1
WORKDIR /src
COPY . .
RUN neojac install && neojac build web && mv dist/web-linux-* /app

# Run: the artifact needs nothing installed. No secrets are baked in: every variable is read at run time.
FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates tzdata && rm -rf /var/lib/apt/lists/*
COPY --from=build /app /app
ENV JAC_WEB_LISTEN=0.0.0.0:3000 JAC_WEB_DATA=/data
VOLUME /data
EXPOSE 3000
CMD ["/app/web"]
