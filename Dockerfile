# Build stage
FROM swift:latest AS builder

WORKDIR /app

# Copy package manifest first for better layer caching
COPY Package.swift ./

# Copy remaining source files and build in release mode
COPY . .

RUN swift build --configuration release

# Run stage — use the full Swift image to ensure all runtime libraries are present
FROM swift:latest

WORKDIR /app

# Copy the full build artefacts and source so swift run is available as a fallback
COPY --from=builder /app /app

EXPOSE 8080

# Run the App target via swift run so the toolchain resolves any runtime dependencies
CMD ["swift", "run", "--configuration", "release"]
