# Kubernetes Microservices — Docker + K8s Deployments

Polyglot microservices platform with identical YouTube summarizer services in Python (FastAPI) and TypeScript (Hono), containerized with Docker and orchestrated on Kubernetes.

## Architecture

```
                  ┌──────────────────────────────┐
                  │   Kubernetes Cluster         │
                  │                              │
                  │  ┌────────────────────────┐  │
                  │  │ Python Service (FastAPI)│  │
Ingress ─────────►│  │ Deployment + Service   │  │
                  │  └────────────────────────┘  │
                  │                              │
                  │  ┌────────────────────────┐  │
                  │  │ TS Service (Hono/Bun)  │  │
                  │  │ Deployment + Service   │  │
                  │  └────────────────────────┘  │
                  └──────────────────────────────┘
```

## Key Features

- **Polyglot Design**: Same API in Python (FastAPI) and TypeScript (Hono) — demonstrates language-agnostic containerization.
- **Docker**: Multi-stage builds for both services.
- **K8s Manifests**: Deployments + Services with proper resource limits.
- **12-Factor**: Environment-based configuration via `.env` files.

## Project Structure

```
├── python-youtube-summarizer/
│   ├── docker/Dockerfile
│   ├── app/
│   ├── k8s/
│   │   ├── deployment.yaml
│   │   └── service.yaml
│   └── .env.example
├── js-yt-summarizer/
│   ├── docker/Dockerfile
│   ├── app/src/
│   ├── k8s/
│   │   ├── deployment.yaml
│   │   └── service.yaml
│   └── .env.example
└── architecture-diagram/
```

## Quick Start

```bash
# Build images
docker build -t yt-summarizer-py -f python-youtube-summarizer/docker/Dockerfile python-youtube-summarizer/
docker build -t yt-summarizer-ts -f js-yt-summarizer/docker/Dockerfile js-yt-summarizer/

# Deploy to K8s
kubectl apply -f python-youtube-summarizer/k8s/
kubectl apply -f js-yt-summarizer/k8s/

# Verify
kubectl get pods,svc
```

## Local Development

```bash
# Python service
cd python-youtube-summarizer/app
pip install -r requirements.txt
uvicorn main:app --reload

# TypeScript service
cd js-yt-summarizer/app
bun install && bun run src/index.ts
```

## Cleanup

```bash
kubectl delete -f python-youtube-summarizer/k8s/
kubectl delete -f js-yt-summarizer/k8s/
```

---
*Part of the [AWS DevOps Portfolio](https://github.com/omesh7/aws-portfolio)*