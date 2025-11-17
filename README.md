# Build support multi-architecture:
```
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --build-arg EZ_VERSION=latest \
  -t vutadev/ezyplatform-app:latest \
  --push \
  .
```