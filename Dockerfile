FROM debian:11-slim

ARG EZ_VERSION=latest
WORKDIR /app
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Etc/UTC

# Database configuration environment variables (can be overridden at runtime)
ENV DB_HOST=localhost \
    DB_PORT=3306 \
    DB_NAME=blog \
    DB_USERNAME="" \
    DB_PASSWORD="" \
    DB_TABLES_CREATE_MANUALLY=false \
    AUTO_START_WEB=false

ADD https://ezyplatform.com/api/v1/platforms/${EZ_VERSION}/download ezyplatform.zip
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        openjdk-11-jre-headless \
        unzip \
        curl \
        cron \
        ca-certificates && \
    unzip ezyplatform.zip && \
    rm ezyplatform.zip && \
    apt-get purge -y unzip && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
WORKDIR /app/ezyplatform

COPY --chmod=755 entrypoint.sh /app/entrypoint.sh
ENTRYPOINT ["/app/entrypoint.sh"]

EXPOSE 9090 8080 3005 2208 2812/udp
