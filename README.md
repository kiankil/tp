# tp — Swift Web App on Railway

A minimal Swift HTTP server that runs on Railway, built with Swift's standard library and no external dependencies.

## Endpoints

| Method | Path      | Response                        |
|--------|-----------|---------------------------------|
| GET    | `/`       | `Hello from Swift on Railway!`  |
| GET    | `/health` | `OK` (used by Railway healthchecks) |

## Run locally

Requires Swift 5.9+ (install via [swift.org](https://swift.org/download/)).

```bash
swift run
```

The server starts on **port 8080** by default.

## Build & run with Docker

```bash
docker build -t tp .
docker run -p 8080:8080 tp
```

## Deploy on Railway

Push to `main` — Railway detects the Dockerfile and builds automatically. The app listens on port `8080` as configured in the `EXPOSE` directive and the `CMD` in the Dockerfile.