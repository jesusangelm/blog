# Stage 1
FROM docker.io/alpine:latest AS build
RUN apk add --update hugo

WORKDIR /opt/HugoApp
COPY . .
RUN hugo 

# Stage 2
FROM docker.io/nginx:stable-alpine
WORKDIR /usr/share/nginx/html
COPY --from=build /opt/HugoApp/public .

EXPOSE 80/tcp
