+++
title = "Desplegando una app Rails en Kubernetes"
date = 2023-04-14
draft = false
tags = ['rails', 'kubernetes', 'devops']
description = "Mi experiencia desplegando una aplicacion Rails real en Kubernetes."
+++

Desde que salió al público Kubernetes, siempre me llamo la atención esta herramienta para desplegar
aplicaciones, pero se me hacía confusa de usar. Además de que en sus inicios crear un clúster Kubernetes
era bastante complicado, yo mismo lo intenté y era muy engorroso, además de que no era muy estable hacerlo
en vps ya que eran propenso a fallos.

En los últimos años, han aparecido servicios administrados de Kubernetes, con lo que es mucho más fácil obtener
un clúster listo para usar. La verdad sí que son fáciles de usar, con solo unos clics y unos minutos, ya tienes un clúster
preparado y listo para desplegar cualquier aplicación dockerizada que desees. Ya no tienes que 
levantar y configurar múltiples VPS, instalar binarios en ellos e interconectarlos para generar el clúster.

Como programador web, Kubernetes otorga la ventaja de desplegar las aplicaciones que desarrolle de forma sencilla y con la posibilidad
de escalar sin muchos inconvenientes.

Desde hace un poco más de un mes para acá, he estado leyendo y aprendiendo un poco sobre Kubernetes, aprovechando las facilidades que hay
ahora para obtener un clúster administrado, me propuse lograr desplegar una aplicación Rails en un clúster Kubernetes lo más parecido posible 
a como sería realizarlo con una aplicación productiva, por lo que a continuación paso a contar un poco mi experiencia en el proceso.

Cabe destacar que no profundizaré demasiado en detalles, por lo que lo más recomendable es tener algo de conocimientos sobre 
**Docker** y **Kubernetes**. En cualquier caso, si ya vienes de conocer lo básico de Docker y leíste mi artículo anterior
[Dockerizando una aplicación Rails](https://jesusmarin.dev/blog/dockerizando-una-aplicacion-rails), lo más relevante que habría que saber
es que se usara la herramienta de línea de comandos llamada `kubectl` la cual nos permite ejecutar comandos en un clúster Kubernetes.

`Kubectl` es simplemente un binario que puedes descargar e instalar en tu S.O. siguiendo los pasos de la [documentación oficial](https://kubernetes.io/docs/tasks/tools/)

En un artículo anterior, ya comenté como se puede dockerizar una aplicación Rails, por lo que 
ya tenemos una imagen Docker de nuestra app Rails la cual podemos ahora desplegar un Kubernetes.

# El Clúster Kubernetes

Primero que nada necesitamos un clúster Kubernetes. Como comento arriba, en la actualidad es muy sencillo obtener uno 
perfectamente funcional en pocos minutos. Proveedores hay un montón, yo usare [Vultr](https://www.vultr.com/?ref=6811149) en este caso.

Crear el clúster en [Vultr](https://www.vultr.com/?ref=6811149) tan solo toma unos cuantos clics y unos minutos, una vez
creado dicho clúster podremos descargar un archivo de configuración el cual se usa para conectarse al clúster y administrarlo.

![Vultr Kubernetes](https://ispz.b-cdn.net/rails/active_storage/blobs/proxy/eyJfcmFpbHMiOnsiZGF0YSI6MTQsInB1ciI6ImJsb2JfaWQifX0=--ff8b5d2f7ebde28cfaca08323ea7023422f05769/vultr_k8s_cluster_2023-04-12_17-48.png)

Generalmente, este archivo es un `.yml` y lo usaremos con `kubectl` para administrar el clúster.

Hay muchas formas de especificar a `kubectl` que archivo de configuración usar, pero la más típica es 
creando en la terminal, una variable de entorno con la ruta del archivo `.yml`

```sh
export KUBECONFIG=/ruta/al/archivo_kubernetes_cluster.yml
```

Una vez creada esta variable de entorno y en esa misma terminal podremos ahora pasar a usar `kubectl` para controlar nuestro nuevo clúster

Podemos probar listando los nodos que pertenecen al clúster

```sh
kubectl get nodes
```

Esto debería mostrar algo como:

```sh
NAME                  STATUS   ROLES    AGE    VERSION
isnode-6e54f270ba11   Ready    <none>   103m   v1.26.2
isnode-86a3f3ea4dad   Ready    <none>   103m   v1.26.2
isnode-eceeea3db344   Ready    <none>   103m   v1.26.2
```

En este caso el clúster creado tiene 3 nodos (vps) y todos tienen `STATUS` **Ready**
por lo que están listos para trabajar.

# Preparativos iniciales

La aplicación que desplegaré en el clúster, es [ImageStorage](https://github.com/jesusangelm/imagestorage), una app Rails 
bastante sencilla que usa una Base de datos PostgreSQL y almacena imágenes en un bucket de 
Idrive E2 el cual es S3 compatible, por lo que es idéntico a usar un bucket S3 de AWS.
Es muy básica la app, pero es realista, ya que usa elementos que generalmente complican despliegues y que comúnmente no se ven muy explicados  en internet.
La app también usa una CDN, pero su configuración es más que todo a nivel de dominio, por lo que es indiferente para Kubernetes.

## La Base de datos
Para que dicha app se ejecute con éxito en el clúster, necesitamos una BD PostgreSQL.
Posiblemente, encontraras en muchos cursos y tutoriales por internet de que la Base de Datos la despliegan
dentro del clúster por simplicidad y facilitar la explicación, pero esto no es lo recomendado en un ambiente 
productivo, ya que al querer escalar ese elemento de la app, las cosas se van a complicar.

Lo ideal sería usar una BD externa al clúster, pero lo suficiente cercana al mismo para reducir la latencia. Si la BD está en el mismo
Datacenter que el clúster, mejor.

Si te fijas bien, muchos proveedores de Kubernetes administrados, ofrecen también Bases de datos administrados, y [Vultr](https://www.vultr.com/?ref=6811149) no es 
la excepción ya que nos permite crear incluso una Base de datos en la misma locación que el clúster, además de opciones de escalado tanto horizontales como vertical.

Esto es lo que usaré, en mi caso, crearé una Base de datos PostgreSQL administrada en [Vultr](https://www.vultr.com/?ref=6811149) y usaremos la url de conexión
que este otorga para que la app rails se conecte a esta BD.

![Vultr PostgreSQL](https://ispz.b-cdn.net/rails/active_storage/blobs/proxy/eyJfcmFpbHMiOnsiZGF0YSI6MjAsInB1ciI6ImJsb2JfaWQifX0=--78b27c493f8c80203870345ea965d973de58d9df/vultr_postgresql_2023-04-12_17-51.png)

## El Ingress controller

Kubernetes está pensado para ser usado con aplicaciones en una arquitectura de microservicios, una aplicación realizada como microservicios se compone de multiples
apps de pequeño tamaño que se encargan de tareas muy específicas, cada uno de estos microservicios puede tener múltiples rutas o path en los que los usuarios realizaran las 
peticiones para consumir la app. Cuando llega el momento de desplegar todos estos microservicios en producción, muy probablemente te encuentres con que tienes múltiples IP o 
dominios distintos correspondientes a cada microservicio que conforma la app, esto hace que consumir dicha app, sea un poco engorrosa, ya que debes estar al tanto de la IP o dominio 
de cada recurso a consumir, Lo ideal sería unificar un poco esas rutas bajo una sola IP o dominio y clasificación.

Es acá donde entra el `Ingress` controller. En Kubernetes, un `Ingress` expone rutas HTTP y HTTPS desde fuera del clúster y las enlaza a `Service` (servicios) dentro del clúster,
el ruteo del tráfico es controlado por reglas definidas en el recurso `Ingress`. Más adelante mostraré como especificamos esta regla y su ruta específica.

En líneas generales y por lo que he visto, un Ingress Controller no es más que una API Gateway. También se asemeja mucho a un proxy, ya que este recibe tráfico y lo 
redirecciona al servicio en donde se requiere. La mayor diferencia a un proxy diría que es debido a que el ingress controller puede hacer tareas de balanceo de carga
y también en el tema de las rutas, las cuales acá son rutas más especificas que no necesariamente abarcan el alcance de un dominio.

En mi caso usaré [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/deploy/). Dije **¿proxy?** Pues acá vez el porqué, ya que este Ingress controller
está basado en Nginx, uno de los servidores HTTP y proxy más conocidos.

Nginx Ingress Controller debe ser desplegado en el clúster para poder ser usado, según su documentación oficial, hay muchas formas de desplegarlo en Kubernetes. Muchas de ellas 
dependen de la implementación de Kubernetes y del proveedor del clúster Kubernetes usado. En mi caso usé el manifiesto básico, el cual se instala con:

```sh
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.6.4/deploy/static/provider/cloud/deploy.yaml
```
Podemos verificar que todo ha ido bien verificando los pods:

```sh
kubectl get pods --namespace=ingress-nginx
```

Deberíamos ver algo así:
```sh
NAME                                        READY   STATUS      RESTARTS   AGE
ingress-nginx-admission-create-fdr5f        0/1     Completed   0          2m33s
ingress-nginx-admission-patch-4n9tv         0/1     Completed   1          2m33s
ingress-nginx-controller-6bdb654777-txgmv   1/1     Running     0          2m33s
```

Nótese que el `ingress-nginx-controller` hay 1 de 1 **READY** y este tiene un **STATUS** `Running`, lo que quiere decir que tenemos un ingress controller ejecutándose.

Algo a tener en cuenta es que cuando desplegamos este Ingress Controller, en [Vultr](https://www.vultr.com/?ref=6811149),
se crea automáticamente un **Balanceador de carga** en tu cuenta [Vultr](https://www.vultr.com/?ref=6811149). Este, Load Balancer otorga una IP pública,
la cual usaremos para acceder a la aplicación. Este será nuestro punto de entrada.

Este comportamiento es muy probable que también ocurra con cualquier otro proveedor Kubernetes administrado.

Más adelante controlaremos este Ingress controller mediante un manifiesto de tipo `Ingress`

## Los manifiestos de Kubernetes

La forma en la que se le especifica a Kubernetes y `kubectl` las acciones que queremos realizar en el clúster, es mediante 
archivos `.yml` que si mal no recuerdo le llaman **manifiesto**. En ellos especificas lo que quieres realizar y como.

Estos **manifiestos** son muy similares a los archivos `docker-compose.yml`. Si has escrito o al menos editado un archivo `docker-compose.yml`
no te será muy difícil entender un **manifiesto** para Kubernetes. En mi experiencia, en lo que más se diferencian es que en estos `.yml` para Kubernetes,
hay acciones que se clasifican en tipos (además de más opciones de configuración o ajuste) y estos tipos de acciones pueden ir en archivos separados o en un mismo archivo.

Esas acciones pueden ser por ejemplo: `Deployment`, `Ingress`, `Service`, entre otras.

Para poder desplegar en el clúster la aplicación Rails, yo usaré dos **manifiestos**, uno para
el `Deployment` y `Service` y otro para el `Ingress`. Dentro de la carpeta raiz de la aplicación Rails,
crearé una carpeta llamada `k8s` y dentro de ella colocaré los archivos `is-depl.yml` y el archivo `ingress-srv.yml`.

```yml {linenos=table,anchorlinenos=true}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: imagestorage-depl
spec:
  replicas: 1
  selector:
    matchLabels:
      app: imagestorage
  template:
    metadata:
      labels:
        app: imagestorage
    spec:
      containers:
        - name: imagestorage
          image: docker-registry.jesusmarin.dev/imagestorage
          env:
            - name: DATABASE_URL
              value: 'postgres://pguser:pgpassw@db_host.com:port/db_name'
            - name: E2_ACCESS_KEY
              value: 'tu_access_key'
            - name: E2_SECRET_ACCESS_KEY
              value: 'tu_secret_access_key'
            - name: E2_REGION
              value: 'miami'
            - name: E2_BUCKET
              value: 'tu_bucket_name'
            - name: E2_ENDPOINT
              value: 'https://endpoint.de.tu.s3provider.com'
            - name: CDN_HOST
              value: 'yourdomain.dev'
            - name: SECRET_KEY_BASE
              value: 'tu_secret_key_base'
      imagePullSecrets:
        - name: regcred 
---
apiVersion: v1
kind: Service
metadata:
  name: imagestorage-srv
spec:
  selector:
    app: imagestorage
  ports:
    - name: imagestorage
      protocol: TCP
      port: 3000
      targetPort: 3000
```
A continuación, explicaré muy brevemente el archivo `is-depl.yml`:
Lo primero que hay que resaltar es que en él se especifica dos acciones, la primera del tipo 
`Deployment` indicado con la keyword **kind** en la línea **2** y luego la segunda acción de tipo `Service`
indicada en la línea **39**. Nótese que en la línea **37** vemos tres guiones `---` el cual nos sirve para separar
los manifiestos que se encuentran en un mismo archivo.

Lo siguiente a destacar está en la línea **17**, allí se indica la imagen que se quiere desplegar en el clúster Kubernetes,
Nótese la similitud con un archivo `docker-compose.yml` en donde podríamos indicar también la imagen a usar. Acá podríamos
colocar fácilmente `image: redmine` como si se tratara de un `docker-compose.yml` que levanta un contenedor de Redmine a partir de la 
imagen **pública** alojada en hub.docker.com, Pero acá y para mi caso en específico, la diferencia está en que la imagen a usar está alojada en un registro **privado**.
Es por eso que tenemos `image: docker-registry.jesusmarin.dev/imagestorage`.

Dado que en mi caso usaré un registro docker privado, necesito indicarle a Kubernetes, como obtener las credenciales de acceso, es por eso que 
en las líneas **35** y **36** vemos: 
```yml {linenos=table,anchorlinenos=true}
imagePullSecrets:
  - name: regcred
```
Lo cual le indica a Kubernetes que las credenciales para el registro privado está en un `secret` llamado `regcred`, más adelante comentaré como crear este `secret`.
Pero si en tu caso la imagen o imágenes docker provienen de un registro público, estas líneas no serían necesarias y puedes eliminarlas.

Por último, lo otro a destacar son las variables de entorno, las mismas que el proyecto tiene en el archivo `example.env` las colocamos acá entre las líneas
**18** a **34**.

Casi se me olvidaba, en la línea **6** vemos `replicas: 1`, es acá donde podemos dar los primeros pasos de escalamiento horizontal, ya que acá
podemos indicar cuantos contenedores de la misma imagen desplegar en el clúster. Si por ejemplo tenemos **3** nodos (vps) en el clúster y acá especificamos `replicas: 3`,
Kubernetes se encargará de levantar **3** contenedores de nuestra app, y muy probablemente se encargara de levantarlos uno en cada nodo, para así tener la app distribuida entre dichos nodos.

En líneas generales, esta parte del manifiesto se encargará de indicarle a Kubernetes, que imagen descargar  y como crear a partir de ella el contenedor.

La segunda parte del manifiesto, es el del tipo `Service` y este se encarga más que todo de permitir que 
el contenedor o contenedores de nuestra app, sean accesibles para otros contenedores en el clúster.
Nótese que indicamos que aplicación será accesible mediante el `selector` `app: imagestorage` de la línea **43** y **44** y también
indicamos puerto y protocolo entre las líneas **45** y **49**.
A todo esta especificación de servicio le damos el nombre de **imagestorage-srv** como se ve en la línea **41**


```yml {linenos=table,anchorlinenos=true}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress-service
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/use-regex: "true"
spec:
  rules:
    - http:
        paths:
          - path: /?(.*)
            pathType: Prefix
            backend:
              service:
                name: imagestorage-srv
                port:
                  number: 3000
```
Este archivo `ingress-srv.yml` es un poco más corto, pero igual de importante. Como mencione arriba, 
se crea un `Service` para permitir que nuestra app sea accesible para otras apps dentro del clúster. Bien, el motivo de esto es permitir que el **Ingress Controller** 
Elegido se conecté con el servicio de la aplicación para poder redireccionarle el tráfico recibido desde el exterior (Internet).

Como indico más arriba, en mi caso usaré Nginx Ingress Controller, y en este archivo lo indicamos en las líneas **6** y **7**.

Igualmente, mencione que los Ingress redireccionan el tráfico mediante **reglas** (rules), pues bien, a partir de la línea **9** las podemos ver,
para este caso solo hay una, y es básicamente una ruta global, donde básicamente decimos
`lo que se que llegue por la ruta '/' redireccionalo al servicio 'imagestorage-srv' en el puerto 3000`

Ese servicio, si nos fijamos, lo definimos en el archivo `is-depl.yml` y corresponde a nuestra app Rails. Con lo que con esto, ya tendríamos 
las especificaciones definidas para acceder a nuestra app desde internet.

## Creando Secrets en el cluster

Como mencione antes, para mi caso en específico, yo use un registro docker privado (alojado en mi casa de hecho) en donde están almacenadas las imágenes docker para estas pruebas,
lo he realizado así dado que en producción, es muy probable que un cliente o empresa para la cual se trabaje, quiera que sus imágenes docker no estén por allí accesibles al público,
por cuestiones de seguridad o de intereses. De esta forma emulo ese caso.

En Kubernetes le podemos especificar las credenciales a usar para identificarse en el registro docker privado con el comando:

```sh
kubectl create secret generic regcred --from-file=.dockerconfigjson=/home/tu-usuario/.docker/config.json --type=kubernetes.io/dockerconfigjson
```
Este comando lo que hace es básicamente tomar la llave o clave de autenticación que usas con docker para autenticarte en un registro docker privado y almacenarla en el clúster 
para luego ser usada cuando se requiera autenticación con dicho registro privado.

Puedes verificar el secret creado con:

```sh
kubectl get secret regcred --output=yaml
```

**NOTA:** Cabe destacar que para que esto funcione, debes haberte primero iniciado sesión en ese registro privado con el comando
```sh
docker login https://registro-docker-privado.com
```
Y lógicamente haber subido la imagen a dicho registro con

```sh 
docker push registro-docker-privado.com/mi-imagen-docker
```


# Desplegando en Kubernetes

Hasta este punto ya tenemos todo listo para desplegar en Kubernetes la aplicación Rails, realizar esto es tan sencillo como dirigirse en 
una terminal a la carpeta raíz de la aplicación y ejecutar el comando:

```sh 
kubectl apply -f k8s/
```
Deberías ver una salida similar a esta:

```sh
ingress.networking.k8s.io/ingress-service created
deployment.apps/imagestorage-depl created
service/imagestorage-srv created
```

y al cabo de unos minutos, verificar el listado de pods:

```sh
kubectl get pods
NAME                                 READY   STATUS    RESTARTS   AGE
imagestorage-depl-5f79658c65-dm6xx   1/1     Running   0          5m20s
```

También podemos ver el `Deployment` que hemos realizado:

```sh
kubectl get deployment
NAME                READY   UP-TO-DATE   AVAILABLE   AGE
imagestorage-depl   1/1     1            1           10m
```

El `Service` que permite que nuestra app sea accesible por otras apps dentro del clúster:

```sh
kubectl get service
NAME               TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
imagestorage-srv   ClusterIP   10.103.143.19   <none>        3000/TCP   11m
```

Y por último pero no menos importante, el `Ingress`

```sh
kubectl get ingress
NAME              CLASS    HOSTS   ADDRESS         PORTS   AGE
ingress-service   <none>   *       149.28.110.18   80      11m
```
En este último comando podemos ver información importante, tenemos la **IP pública** y puerto, esto pertenece al Load Balancer 
que se creyó automáticamente en [Vultr](https://www.vultr.com/?ref=6811149) al instalar el Nginx Ingress Controller.


Nuestro único pod ya está ejecutándose, con lo que el deploy ha sido exitoso, bueno no del todo, todavía falta algunos pasos claves.

![ImageStorage deployed on Kubernetes](https://ispz.b-cdn.net/rails/active_storage/blobs/proxy/eyJfcmFpbHMiOnsiZGF0YSI6MTYsInB1ciI6ImJsb2JfaWQifX0=--43f26c31bcd513fa13496b029857e782fd8fe05c/imagestorage_kubernetes-2023-04-13_14-50.png)

# Ejecutando comandos dentro del clúster

Comúnmente las aplicaciones Rails que usan base de datos, al ejecutarlas por primera vez, se deben correr las llamadas **migraciones**, estos son 
instrucciones para generar las tablas de la base de datos y demás estructuras relacionadas, y esta app no es una excepción.

Para ejecutar un comando en Kubernetes, podemos usar el siguiente comando para obtener una terminal dentro del pod:

```sh
kubectl exec -it imagestorage-depl-5f79658c65-dm6xx -- /bin/bash
```
Nótese que se debe especificar el pod el cual en mi caso es `imagestorage-depl-5f79658c65-dm6xx`

Con esto obtendremos una nueva terminal pegada al pod de la aplicación con la que podemos ejecutar comandos rails como por ejemplo:

```sh
root@imagestorage-depl-5f79658c65-dm6xx:/app# bin/rails db:migrate
I, [2023-04-13T19:08:40.246748 #24]  INFO -- : Migrating to DeviseCreateAdminUsers (20230306185110)
== 20230306185110 DeviseCreateAdminUsers: migrating ===========================
-- create_table(:admin_users, {:id=>:uuid})
   -> 0.0095s
-- add_index(:admin_users, :email, {:unique=>true})
.
.
.
```

Una vez ejecutada las migraciones y cualquier otro comando necesario para los preparativos iniciales, solo queda comprobar vía el navegador que la app 
se ejecuta como esperamos.

![ImageStorage ActiveAdmin](https://ispz.b-cdn.net/rails/active_storage/blobs/proxy/eyJfcmFpbHMiOnsiZGF0YSI6OCwicHVyIjoiYmxvYl9pZCJ9fQ==--0e5a4bec12604fe3e0325e453e7bfcc22a6332f2/imagestorage_adminpanel-2023-04-13_15-28.png)

# Escalando horizontalmente mediante los manifiestos

Como comente hace poco, el manifiesto `is-depl.yml` contiene una especificación llamada `replicas` en la que podemos definir 
la cantidad de instancias iniciales de nuestra aplicación al momento de hacer el despliegue.

Si editamos esa especificación y colocamos por ejemplo **3**, al aplicar nuevamente el manifiesto, podremos aumentar la cantidad de 
instancias de la app Rails.

```sh
kubectl apply -f k8s/is-depl.yml

deployment.apps/imagestorage-depl configured
service/imagestorage-srv unchanged
```

Vamos a verificar los pods:

```sh
kubectl get pods -o wide

NAME                                 READY   STATUS    RESTARTS   AGE     IP              NODE                   NOMINATED NODE   READINESS GATES
imagestorage-depl-5f79658c65-dm6xx   1/1     Running   0          60m     10.244.118.6    is-node-23d25cf53ce4   <none>           <none>
imagestorage-depl-5f79658c65-mzjjj   1/1     Running   0          4m12s   10.244.122.69   is-node-170030fb7224   <none>           <none>
imagestorage-depl-5f79658c65-xl7lx   1/1     Running   0          4m12s   10.244.16.195   is-node-56c90167e4c5   <none>           <none>
```
Esta vez usamos el flag `-o wide` en el comando para mostrar más información, así apreciamos que los nuevos pods o instancias de la app Rails fueron agregados
en otros dos nodos (vps) que conforman el clúster Kubernetes.

# Conclusión

Esto ha sido una pequeña demostración lo más cercana a la realidad que pude realizar como experimento para desplegar una aplicación Rails en 
un clúster Kubernetes. Lógicamente, Kubernetes abarca muchas más funciones, hay otros ajustes posibles para la app como por ejemplo la asignacion
de un dominio y un certificado SSL; sin embargo, creo que con este experimento se logra aprender mucho los temas básicos requeridos para desplegar 
cualquier otra aplicación en Kubernetes.

Cabe destacar que acá hemos usado un clúster administrado, el cual se crea en pocos minutos con solo unos clics,
pero hay proyectos open-source que te permiten crear por ti mismo un clúster funcional en poco tiempo y sin agregar mucha complejidad.
Este es el caso de [K3S](https://k3s.io/) y [K3Sup](https://github.com/alexellis/k3sup) y lo mejor de todo es que puedes elegir tú, que quieres que sean tus nodos,
un VPS, un servidor dedicado, una Raspberry PI, etc.
