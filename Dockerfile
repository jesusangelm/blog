# Stage 1
FROM docker.io/debian:trixie-slim AS build
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl ca-certificates && \
    curl -sSL "https://github.com/gohugoio/hugo/releases/download/v0.167.0/hugo_extended_0.167.0_Linux-64bit.tar.gz" \
    -o /tmp/hugo.tar.gz && \
    tar -xzf /tmp/hugo.tar.gz -C /usr/local/bin hugo && \
    chmod +x /usr/local/bin/hugo && \
    rm /tmp/hugo.tar.gz && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /opt/HugoApp
COPY . .
RUN hugo --minify

# Stage 2
FROM docker.io/nginx:stable-alpine
COPY nginx/default.conf /etc/nginx/conf.d/default.conf
COPY --from=build /opt/HugoApp/public /usr/share/nginx/html

EXPOSE 80/tcp
HEALTHCHECK CMD wget --spider http://localhost/ || exit 1
