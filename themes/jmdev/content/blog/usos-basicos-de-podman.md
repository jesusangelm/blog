+++
title = "Usos básico de Podman"
date = 2024-05-01
draft = false
tags = ['podman', 'sysadmin', 'devops']
description = "Anotaciones de uso básico de Podman en Linux."
+++

De su repositorio Github.

> Podman (the POD MANager) es una herramienta para gestionar contenedores e imágenes, volúmenes montados en esos contenedores y pods formados a partir de grupos de contenedores. Podman ejecuta contenedores en Linux, pero también puede utilizarse en sistemas Mac y Windows utilizando una máquina virtual gestionada por Podman. Podman se basa en libpod, una biblioteca para la gestión del ciclo de vida de los contenedores que también se encuentra en este repositorio. La librería libpod proporciona APIs para la gestión de contenedores, pods, imágenes de contenedores y volúmenes.
{class="blockquote"}

Podman, al igual que Docker, es una herramienta de gestión de contenedores que nos permite ejecutar aplicaciones en un entorno aislado del sistema huésped,
en este caso un contenedor, esto nos ayuda por ejemplo en lograr una buena portabilidad en nuestras aplicaciones haciendo que estas puedan ser desplegadas en
una mayor variedad de entornos.

Cuando comienzas a usar Podman, notaras mucha similitud con docker, se podría decir que demasiada, esto se podría decir que es intencional, Podman es
compatible con otros formatos de contenedor que son compatibles con [OCI](https://opencontainers.org/), entre ellos docker. De allí que casi todos los comandos 
que usas en Docker, puedan ser usados en Podman. Esto facilita también una transición desde Podman hacia Docker.

Sin embargo, y a pesas de dichas similitudes, hay también diferencias, la más destacada y la más mencionada es que Podman es seguro, este se refiere más que todo 
en que los contenedores en Podman, por defecto, se ejecutan con los permisos del usuario que lo ejecuta, y
no con los permisos o privilegios de **root** como lo hace docker. Esta característica le llaman "Rootless containers".

Otra diferencia o característica de Podman con respecto a Docker se puede conseguir en su nombre, y no. No me refiero a que se llaman distinto. Me refiero
a que Podman viene de **POD** **MAN**ager. Si has leído o usado Kubernetes, sabrás que los pods son las unidades de computación desplegables más 
pequeñas que se pueden crear y gestionar en Kubernetes. Y es que en podman, podemos crear, iniciar, inspeccionar y administrar pods compatibles con Kubernetes.
De hecho, a partir de un pod creado en podman, se puede crear un manifiesto `YAML` que luego puede ser usado en Kubernetes.

# Instalación

En distribuciones Linux, muy seguro ya haya un paquete disponible en su respectivo repositorio.
En Debian por ejemplo, basta con un simple

```sh
sudo apt install podman
```

Para otras distros y Sistemas operativos, se recomienda seguir la [documentación oficial](https://podman.io/docs/installation)

# Generando imágenes

Como comente más arriba, Podman es muy similar a docker debido a que es OCI compatible, esto hace que la mayoría de las instrucciones que usamos 
en un `Dockerfile` cuando generamos imágenes con Docker, las podemos usar también en Podman.

Por ejemplo, el siguiente `Dockerfile` para generar una imagen de este blog.

```Dockerfile {linenos=table,anchorlinenos=true}
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
```

Si habrás usado Docker antes, notaras que es prácticamente idéntico a un Dockerfile escrito para Docker.

Acá la única diferencia a destacar es: la segunda línea `FROM docker.io/alpine:latest AS build` en donde seguro 
la has visto simplemente como `FROM alpine:latest AS build`. Esto es un ajuste que hago debido a que Podman no 
da por sentado que descargaremos imágenes del registro en `docker.io`, hay muchos registros de contenedores públicos y privados
y `docker.io` no es el único. Esto se puede cambiar en las configuraciones de podman, pero personalmente prefiero hacer este ajuste en mis
`Dockerfile`, el ajuste es compatible con Docker, así que este `dockerfile` es compatible tal cual con docker de todos modos.

Para generar esta imagen basta con ejecutar:

```sh
podman build -t localhost/blog -f Dockerfile .
```

Nótese que no necesito ejecutar el comando con `sudo`, esto genera la imagen con los permisos del usuario.

A su vez le indico un tag con `-t localhost/blog` e indico el archivo Dockerfile `-f Dockerfile`

Todo esto es muy similar (o idéntico) a Docker. Si has usado Docker antes, no tienes perdida.

# Imágenes

### Listando imágenes

Lo mismo que con Docker

```sh
podman images
```

### Inspeccionando imágenen

```sh
podman inspect ID_IMAGEN
```

### Eliminando imágenen

```sh
podman rmi ID_IMAGEN
```

# Contenedores

### Listando contenedores

```sh
podman ps -a
```

Deja-vu, en Docker es idéntico.

# Redes

### Creando red sencilla

```sh
podman network create mi_red
```
Para listar las redes, inspeccionarlas y eliminarlas es lo mismo que en Docker.

# Volúmenes

### Creando Volúmen

```sh
podman volume create mi_volume
```
Para listar los volumenes, inspeccionarlos y eliminarlis es lo mismo que en Docker.


# Ejecución

### Corriendo un contenedor

```sh
podman run -d --restart=unless-stopped --name blog localhost/blog -p 8080:80
```
¿Nada nuevo acá, verdad? De nuevo, si has usado docker, ya sabes de qué va todo esto.

Algo a tener en cuenta con Podman es que debido a que es rootless por defecto, las imágenes. Contenedores que sean creados por 
un usuario no son visible o usables por otros usuarios. Yo como usuario `fulanito` en un sistema, no puedo ver ni usar 
las imágenes o contenedores que genero o descargo el usuario `root`.

Teniendo en cuenta esto, si construimos o descargamos una imagen con el comando `sudo` y luego al intentar correrla olvidamos 
anteponer `sudo` en el comando `podman run`, el mismo no funcionará, ya que el comando `podman run` no estará corriendo con privilegios de **root**
por lo que no tendrá acceso al listado de imágenes que este tiene.

# Pod

Esta es la parte interesante de Podman, los pods.

Como comente antes, los pod son las unidades de cómputo desplegables más pequeñas que se pueden crear y gestionar en Kubernetes, y en podman es similar.

Podemos crear un pod para ejecutar uno o más contenedores, similar a como es típico en Kubernetes, podrimos crear un pod por contenedor y asi aislar el mismo de 
otros pods y contenedores, además de gestionar sus recursos de forma independiente y a nivel de pod.

### Creando un pod


Primero que nada acostumbro a crear una red para cada aplicación, de esta forma si más adelante necesito que algún contenedor se comunique 
con otro contenedor, puedo hacerlo a nivel de red sin importar que dichos contenedores estén aislados cada uno en un pod. Para los contenedores 
será como comunicarse con un dispositivo en su red local.

```sh
podman network create blog_net
```

Luego si paso a crear el pod, especificando que use la red que acabo de crear.
```sh
podman pod create --name blog --network blog_net -p 8080:80
```

Por último, ejecuto el contenedor deseado, dentro del pod creado.

```sh
podman run -d --pod blog --restart=unless-stopped --name miblog localhost/blog
```

A tener en cuenta:

Nótese que los puertos requeridos por el contenedor, los estoy especificando en la creación del pod, no en la ejecución del contenedor.
Esto debido a que, como ya comente varias veces antes, el pod es la unidad más pequeñas que se pueden crear y gestionar en Kubernetes y podman al 
ser "Kubernetes ready" comparte el mismo principio. Por lo que en un pod la carga de trabajo es el pod mismo y no el contenedor o contenedores que estén adentro.

A mi modo de ver, es como si el pod fuese el contenedor y el contenedor adentro del pod fuese la aplicación.


Otra cosa a tener en cuenta es que el nombre del contenedor y el pod no pueden ser el mismo. Nuevamente, el pod es como si fuese nuestra aplicación,
por lo que pasaremos a administrar el pod y no el contenedor dentro de él.

### Listando pods

Ejecutamos
```sh
podman pod ls
```

veremos algo como:
```sh
POD ID        NAME            STATUS      CREATED       INFRA ID      # OF CONTAINERS
e9bb3b00da03  blog            Running     4 days ago    b16c1ec87d50  2
```

Hay algo que nos podría parecer raro al inicio acá, vemos que el pod contiene 2 contenedores, pero solo hemos agregado uno.

Veamos de nuevo el listado de contenedores:
```sh
podman ps -a
```

vemos algo como:

```sh
CONTAINER ID  IMAGE                                   COMMAND               CREATED       STATUS           PORTS                      NAMES
b16c1ec87d50  localhost/podman-pause:4.3.1-0                                4 days ago    Up 4 days ago    8080->80/tcp    e9bb3b00da03-infra
16556eb68650  localhost/blog:latest                   nginx -g daemon o...  4 days ago    Up 4 days ago    8080->80/tcp    miblog
```
Bien, allí está el contenedor que ejecutamos dentro del pod, pero también está otro llamado `e9bb3b00da03-infra`, pues bien, este contenedor siempre
se agrega al crear un pod en podman y es el encargado de gestionar los recursos para el contenedor dentro del pod.

# Administrando pods

Como comente antes, cuando agregamos un pod a un contenedor, pasamos a administrar el pod y no el contenedor, es por eso que para:

### Inspeccionar pod

ejecutamos

```sh
podman pod inspect nombre_pod
```

### Detener un pod

ejecutamos

```sh
podman pod stop nombre_pod
```
Nuevamente, administramos el pod, no el contenedor, por lo que esto detiene el pod y los contenedores que estos estén ejecutando.

### Iniciar un pod detenido

ejecutamos

```sh
podman pod start nombre_pod
```

### Eliminar un pod

ejecutamos

```sh
podman pod rm nombre_pod
```
El pod debe estar detenido previamente, esto eliminará también los contenedores que estén en el pod.

# Podman-compose o no Podman-compose
Viniendo de Docker, ya sabrás que es Docker Compose, esta herramienta que te permite escribir un `.yml` en donde específicas 
que imágenes de contenedores ejecutar y como lo debe ejecutar, enlazar los contenedores descritos, crearles una red propia, volúmenes, etc. Todo
todo ejecutable desde un solo comando. Muy útil para ejecutar múltiples contenedores a la vez.

Bien, en Podman hay una herramienta similar llamada **podman-compose**; sin embargo, personalmente no he tenido buena experiencia con ella, por lo que he leído
es una herramienta nueva en podman y todavía hay características en docker-compose que no está implementadas en podman.

En mi caso y de momento he sustituido las necesidades de un **docker-compose**/**podman-compose** con los **pod** de podman e instrucciones `Makefile`

Un ejemplo de eso es este [Makefile](https://github.com/jesusangelm/api_galeria/blob/main/Makefile) en el proyecto 
*api_galeria* que hice hace poco mientras aprendía **Golang**

En el específico, los comandos podman necesarios para la creación de la red, los volúmenes, pods y contenedores para ejecutar la app con podman.
Incluso agrupo todos esos múltiples comando en uno solo `galeria/build` y `galeria/deploy` para construcción y ejecución respectivamente.


# Conclusión

Podman al igual que Docker es una herramienta que te ayudara en tu día a día en el desarrollo y despliegue de aplicaciones, hacerlas más portables, asegurarte
que se ejecuten debidamente en casi cualquier máquina y sistema operativo. Con podman ganarás el plus de que tu aplicación ejecute en un entorno un poco más 
seguro cuando despliegues en producción debido a su característica `rootless` por defecto.

Podman también te ayudaba cuando tus aplicaciones requieran escalar horizontalmente, ya que al usar pods desde un principio tan solo necesitarás
generar un manifiesto Kubernetes de tus pods para luego, con algunos pocos ajustes, desplegarlo en un entorno Kubernetes.
