# Stage 1
FROM docker.io/alpine:3.19 AS build
RUN apk add --update hugo

WORKDIR /opt/HugoApp
COPY . .
RUN hugo --minify

# Stage 2
FROM docker.io/nginx:stable-alpine
COPY nginx/default.conf /etc/nginx/conf.d/default.conf
COPY --from=build /opt/HugoApp/public /usr/share/nginx/html

EXPOSE 80/tcp
HEALTHCHECK CMD wget --spider http://localhost/ || exit 1