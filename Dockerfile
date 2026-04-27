# Build stage
FROM swift:latest AS builder

WORKDIR /app

# Copy package manifest and resolve dependencies first (layer caching)
COPY Package.swift ./
COPY Package.resolved ./

RUN swift package resolve

# Copy remaining source files and build in release mode
COPY . .

RUN swift build --configuration release

# Run stage
FROM swift:slim

WORKDIR /app

# Copy the compiled binary from the build stage
COPY --from=builder /app/.build/release /app/.build/release

EXPOSE 8080

# Run the executable — replace 'App' with your actual target name if different
CMD ["/app/.build/release/App"]
