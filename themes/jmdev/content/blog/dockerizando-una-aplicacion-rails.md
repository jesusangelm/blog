+++
title = "Dockerizando una aplicación Rails"
date = 2023-02-13
draft = false
tags = ['docker', 'rails', 'devops']
description = "Una guía básica para dockerizar una aplicación rails real."
+++

Desde que trabajo como programador he usado contenedores Docker en mis entornos de desarrollo, el principal uso que les he dado es principalmente para los servidores de bases de datos en local, en lugar de instalar en el sistema operativo un servidor PostgreSQL, Redis o MongoDB, simplemente iniciaba un contenedor y listo, ya tenía lo que necesitaba para que las aplicaciones persistan su estado.

Sin embargo, sabía que podía sacarle más provecho a Docker si lo usaba para algo más que bases de datos en local, por lo que hice mis primeras pruebas para dockerizar algunas de mis aplicaciones Rails; sin embargo, en este primer intento, no tuve mucho éxito. Constantemente presentaba problemas a la hora de compilar assets, preparar las variables de entorno a mi gusto y conectar con el contenedor de base de datos en aplicaciones que lo requerían.

Era lógico que me faltaba entender un poco más la forma en la que Docker trabaja, de ese primer intento ya hace unos tres años.

Unas semanas atrás, cuando estaba desplegando una aplicación rails en [Fly.io](https://fly.io), note que localmente el cliente de esta PaaS crea un archivo Dockerfile, el cual usa para construir una imagen desplegable de la aplicación Rails. Este archivo me llamo tanto la atención, que pase un buen rato leyéndolo y aprendiendo todo lo que podía de él.

Luego de eso decidí que este simple archivo podría facilitarme mucho el camino para crear mis propias imágenes de mis aplicaciones Rails, por lo que lo modifique un poco para una de mis aplicaciones experimentales.


Este fue el resultado:
```dockerfile {linenos=table,anchorlinenos=true}
# syntax = docker/dockerfile:experimental

# Dockerfile used to build a deployable image for a Rails application.
# Adjust as required.
#
# Common adjustments you may need to make over time:
#  * Modify version numbers for Ruby, Bundler, and other products.
#  * Add library packages needed at build time for your gems, node modules.
#  * Add deployment packages needed by your application
#  * Add (often fake) secrets needed to compile your assets

#######################################################################

# Learn more about the chosen Ruby stack, Fullstaq Ruby, here:
#   https://github.com/evilmartians/fullstaq-ruby-docker.
#
# We recommend using the highest patch level for better security and
# performance.

ARG RUBY_VERSION=3.1.3
ARG VARIANT=jemalloc-slim
FROM quay.io/evl.ms/fullstaq-ruby:${RUBY_VERSION}-${VARIANT} as base

LABEL fly_launch_runtime="rails"

ARG BUNDLER_VERSION=2.4.4

ARG RAILS_ENV=production
ENV RAILS_ENV=${RAILS_ENV}

ENV RAILS_SERVE_STATIC_FILES true
ENV RAILS_LOG_TO_STDOUT true

ARG BUNDLE_WITHOUT=development:test
ARG BUNDLE_PATH=vendor/bundle
ENV BUNDLE_PATH ${BUNDLE_PATH}
ENV BUNDLE_WITHOUT ${BUNDLE_WITHOUT}

RUN mkdir /app
WORKDIR /app
RUN mkdir -p tmp/pids

RUN gem update --system --no-document && \
    gem install -N bundler -v ${BUNDLER_VERSION}

#######################################################################

# install packages only needed at build time

FROM base as build_deps

ARG BUILD_PACKAGES="git build-essential libpq-dev wget vim curl gzip xz-utils libsqlite3-dev"
ENV BUILD_PACKAGES ${BUILD_PACKAGES}

RUN --mount=type=cache,id=dev-apt-cache,sharing=locked,target=/var/cache/apt \
    --mount=type=cache,id=dev-apt-lib,sharing=locked,target=/var/lib/apt \
    apt-get update -qq && \
    apt-get install --no-install-recommends -y ${BUILD_PACKAGES} \
    && rm -rf /var/lib/apt/lists /var/cache/apt/archives

#######################################################################

# install gems

FROM build_deps as gems

COPY Gemfile* ./
RUN bundle install && rm -rf vendor/bundle/ruby/*/cache

#######################################################################

# install deployment packages

FROM base

ARG DEPLOY_PACKAGES="postgresql-client file vim curl gzip libsqlite3-0 libvips-tools libvips-dev nodejs ffmpeg"
ENV DEPLOY_PACKAGES=${DEPLOY_PACKAGES}

RUN --mount=type=cache,id=prod-apt-cache,sharing=locked,target=/var/cache/apt \
    --mount=type=cache,id=prod-apt-lib,sharing=locked,target=/var/lib/apt \
    apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    ${DEPLOY_PACKAGES} \
    && rm -rf /var/lib/apt/lists /var/cache/apt/archives

# copy installed gems
COPY --from=gems /app /app
COPY --from=gems /usr/lib/fullstaq-ruby/versions /usr/lib/fullstaq-ruby/versions
COPY --from=gems /usr/local/bundle /usr/local/bundle

#######################################################################

# Deploy your application
COPY . .

# Adjust binstubs to run on Linux and set current working directory
RUN chmod +x /app/bin/* && \
    sed -i 's/ruby.exe\r*/ruby/' /app/bin/* && \
    sed -i 's/ruby\r*/ruby/' /app/bin/* && \
    sed -i '/^#!/aDir.chdir File.expand_path("..", __dir__)' /app/bin/*

# The following enable assets to precompile on the build server.  Adjust
# as necessary.  If no combination works for you, see:
# https://fly.io/docs/rails/getting-started/existing/#access-to-environment-variables-at-build-time
ENV SECRET_KEY_BASE 1
# ENV AWS_ACCESS_KEY_ID=1
# ENV AWS_SECRET_ACCESS_KEY=1

# Run build task defined in lib/tasks/fly.rake
ARG BUILD_COMMAND="bin/rails fly:build"
RUN ${BUILD_COMMAND}

# Default server start instructions.  Generally Overridden by fly.toml.
ENV PORT 3000
EXPOSE 3000
ARG SERVER_COMMAND="bin/rails server -b 0.0.0.0"
ENV SERVER_COMMAND ${SERVER_COMMAND}
CMD ${SERVER_COMMAND}
```

A simple vista, es lógico pensar que todavía conserva características que lo enlazan
a la plataforma [Fly.io](https://fly.io), un ejemplo claro es el argumento:
`ARG BUILD_COMMAND="bin/rails fly:build"` el cual ejecuta una tarea Rake para 
compilar assets, por cierto, dicha tarea Rake es agregada por la CLI de 
[Fly.io](https://fly.io) y es reemplazable por algo como
`ARG BUILD_COMMAND="bin/rails assets:precompile"`.
Pero cumple con lo requerido si quieres una imagen de tu app
Rails que pueda ser desplegada en otro entorno.

No me detuve allí, a fin de cuentas, el Dockerfile tan solo crea la imagen de 
la app Rails, pero Docker puede hacer más, con tan solo un `docker-compose.yml`
se podría desplegar la imagen en cualquier VPS o servidor dedicado con tan solo
un comando, si este cuenta con Docker ya instalado.

Lógicamente, el CLI de [Fly.io](https://fly.io) no genera un archivo docker-compose.yml, por lo que
tenía que crearlo desde cero, este fue el resultado luego de varios intentos:

```yml {linenos=table,anchorlinenos=true}
version: "3.9"
services:
  web:
    build:
      context: .
      dockerfile: ./Dockerfile
    env_file:
      - .env
    depends_on:
      - db
    ports:
      - "3000:3000"

  db:
    image: "postgres:15-alpine"
    restart: always
    volumes:
      - pg-vol:/var/lib/postgresql/data
    environment:
      POSTGRES_USER: usuario-postgres
      POSTGRES_PASSWORD: tu-password-mas-segura-para-postgres-aqui
    ports:
      - "5432:5432" 

volumes:
  pg-vol:
```

Como comente antes, una de las cosas que más problemas me dio en el pasado, era la compilación de los assets y la conexión de la app con el contenedor de base de datos. Esta vez la solucion fue administrar mejor las variables de entorno y dejar la compilación de assets para el momento en que se genera la imagen (el Dockerfile).

Las variables de entornos se cargan mediante un archivo `.env` y se hacen en el `docker-compose.yml`, ya que estas de momento, solo las necesito cuando la app se está ejecutando y no tanto cuando se está generando la imagen de la misma.

El archivo `.env` se ve como este:
```sh {linenos=table,anchorlinenos=true}
# .env
DATABASE_URL=postgres://usuario-postgres:tu-password-mas-segura-para-postgres-aqui@db/usuario-postgres

B2_ACCESS_KEY=
B2_SECRET_ACCESS_KEY=
B2_REGION=us-west-001
B2_BUCKET=
B2_ENDPOINT=

CDN_HOST=localhost
````

Acá lo más importante es definir debidamente `DATABASE_URL`, esta se compone de 
el usuario y clave de la base de datos, definido en el `docker-compose.yml` de arriba,
el nombre de la base de datos, el cual y para este caso en específico es el mismo usuario 
de la base de datos, y el hostname de la base de datos, el cual será `db` para este ejemplo, ya que fue el nombre que le dimos en el `docker-compose.yml` arriba.

La aplicación de ejemplo usada, fue una galería hecha en Rails, la cual almacena las 
Imágenes a [Backblaze B2](https://www.backblaze.com/b2/cloud-storage.html) mediante su API compatible con S3. Dichas imágenes descargan
de forma eficiente mediante la [CDN de Gcore](https://gcore.com/cdn), es por eso que ven esas variables
de entornos adicionales.

Con estos tres archivos, ya podemos generar y ejecutar una aplicación Rails
dentro de un contenedor Docker con el comando `docker compose up -d`

Para este punto tal vez se preguntaran como correr las migraciones, el seed o una 
rake task, pues es tan simple como ejecutar: `docker compose run web bin/rails db:migrate
` o `docker compose run web bin/rails db:seed`. Lo importante acá son dos cosas:

- el `web` que indica que ejecutamos el comando en un contenedor web (el de la app)
- el comando, el cual puede ser algo como `bin/rails console` o `bin/rake tu-tarea`

Con esto ya se es capaz de desplegar la app en un VPS o servidor dedicado donde se ejecute 
Docker. También da paso a ir más allá y poder desplegar la aplicación en un entorno
más escalable como un clúster Kubernetes.


