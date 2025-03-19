+++
title = "Creando un cluster Kubernetes con K3s y K3sup"
date = 2023-04-25
draft = false
tags = ['kubernetes', 'devops', 'k3s', 'k3sup']
description = "Pasos basicos para crear un cluster kubernetes desde cero, ligero y funcional."
+++

![K3sup logo](https://is.jesusmarin.net/rails/active_storage/representations/redirect/eyJfcmFpbHMiOnsiZGF0YSI6MTAsInB1ciI6ImJsb2JfaWQifX0=--a83c6d9f279b67ec9870f3924a08cb38648efb13/eyJfcmFpbHMiOnsiZGF0YSI6eyJmb3JtYXQiOiJwbmciLCJyZXNpemVfdG9fbGltaXQiOlszNTAsMzUwXX0sInB1ciI6InZhcmlhdGlvbiJ9fQ==--9744bf5f7a4d2a91fff7932a7126070765a68041/k3sup.png)

Como he comentado ya, desde hace poco he estado aprendiendo un poco acerca de Kubernetes. Luego
de probar algunas soluciones de clúster administrado, me interesé por la posibilidad de 
desplegar un clúster desde cero con las máquinas o VPS de mi elección para así poder
comprender un poco más la arquitectura y funcionamiento de Kubernetes.

Sin embargo, tampoco me quería complicar la vida como en el pasado cuando Kubernetes 
tenía poco tiempo de haber salido al público, realmente es innecesario dado que en la 
actualidad hay múltiples formas de crear un clúster Kubernetes desde cero sin 
mucha complicación.

Una herramienta que ayuda a llevar a cabo esto es [K3s](https://k3s.io/), el cual
es un simple binario en el que se empaqueta todo lo necesario para tener un clúster 
Kubernetes listo para producción. Además de esto, **K3s** está optimizado para 
operar en arquitectura ARM, lo cual lo hace ideal para ser usado en Raspberry Pi o 
servidores/vps ARM. ¿Quieres crear un clúster Kubernetes con varias RPI? Con **K3s** lo 
Podrás hacer sin muchas complicaciones.

Sin embargo, en mi experiencia, usar **K3s** me pareció un poco confuso. además de 
tener unos cuantos errores. Uno de ellos al intentar desactivar **traefik** el cual es 
el ingress controller por defecto. La documentación tampoco me pareció que fuese clara, ya que 
los flags indicados no parecían hacer lo que esperaba. Tal vez necesitaba 
dedicarle un poco más de tiempo.

Intentando lograr mi cometido me encontré con la herramienta 
[K3Sup](https://github.com/alexellis/k3sup) la cual es un solo binario que 
permite instalar y configurar Kubernetes desde cero en cualquier VPS o máquina local
con tan solo unos pocos comandos. Esto lo hace instalando nada más y nada menos 
que [K3S](https://k3s.io/) en esas máquinas.

Y la verdad sí que es fácil de usar, pues logre mi cometido con tan solo unos 3 
comandos para crear el clúster tal como lo quería configurado y uno para instalar 
el ingress controller deseado.

# El clúster Kubernetes

En esta ocasión usaré tres VPS de [Hetzner](https://hetzner.cloud/?ref=lSUdD7BtOZHd), 
un vps será para el **control plane** o nodo master
y los otros dos vps serán para los nodos **worker**. El S.O que he elegido para los 
vps ha sido **Debian**, pero pueden usar cualquier otro siempre y cuando sea bajo la 
arquitectura **X86_64** o **ARM**.

## Instalando k3sup en local
Según la documentación oficial, para instalarlo en la máquina desde donde vas a controlar tú
Clúster, solo necesitarás ejecutar los siguientes comandos:

```sh {linenos=table,anchorlinenos=true}
curl -sLS https://get.k3sup.dev | sh
sudo install k3sup /usr/local/bin/
```
La forma en la que trabaja [K3Sup](https://github.com/alexellis/k3sup) es conectándose
mediante SSH a las máquinas o VPS Linux remoto para realizar la instalación y 
Configuración de **K3s** por lo que es necesario poder tener a disposición 
el acceso ssh a dichas máquinas.

## Creando el control plane
Para crear el control plane o nodo master del cluster tan solo debemos ejecutar el comando:

```sh
k3sup install --ip=5.161.212.25 --user=root --k3s-channel=stable --local-path=config.k3s-server.yaml --k3s-extra-args='--disable traefik'
```
**NOTA:** Cabe destacar que le he agregado mi llave SSH a los vps al momento de crearlos
en el panel de [Hetzner](https://hetzner.cloud/?ref=lSUdD7BtOZHd). Recomiendo que copies 
tu llave ssh **pública** a la máquina remota antes de usar **k3sup** contra dichas máquinas.

Pasaré a explicar brevemente el comando usado:

Lógicamente, ejecutamos el comando `install` de **K3sup**, el cual se le pasan algunos flags
como por ejemplo:

- `--ip` para indicar la IP de la máquina Linux remota. En este caso un VPS.
- `--user` para indicar el nombre del usuario en la máquina Linux remota, en este caso **root**
dado que se necesitan sus privilegios para la instalación de **K3s** dentro del VPS.
- `--k3s-channel` para indicar si queremos una versión específica de **K3s**, aca indicamos `stable` para la versión estable de **K3s**
- `--local-path` para indicar la ubicación y nombre del archivo de configuración de clúster Kubernetes que nos permitirá conectarnos a este mediante **kubectl**
- `--k3s-extra-args` para pasarle argumentos a **K3s**, en mi caso deshabilitar traefik. Si quieres usar traefix, no uses este último flag.

Hay muchos otros flags en la documentación oficial de [K3Sup](https://github.com/alexellis/k3sup).

Bien, una vez ejecutado el comando, deberíamos ver algo como:

```sh
Running: k3sup install
2023/04/24 11:16:54 5.161.228.127
Public IP: 5.161.228.127
[INFO]  Finding release for channel stable
[INFO]  Using v1.26.3+k3s1 as release
[INFO]  Downloading hash https://github.com/k3s-io/k3s/releases/download/v1.26.3+k3s1/sha256sum-amd64.txt
[INFO]  Downloading binary https://github.com/k3s-io/k3s/releases/download/v1.26.3+k3s1/k3s
[INFO]  Verifying binary download
[INFO]  Installing k3s to /usr/local/bin/k3s
[INFO]  Skipping installation of SELinux RPM
[INFO]  Creating /usr/local/bin/kubectl symlink to k3s
[INFO]  Creating /usr/local/bin/crictl symlink to k3s
[INFO]  Creating /usr/local/bin/ctr symlink to k3s
[INFO]  Creating killall script /usr/local/bin/k3s-killall.sh
[INFO]  Creating uninstall script /usr/local/bin/k3s-uninstall.sh
[INFO]  env: Creating environment file /etc/systemd/system/k3s.service.env
[INFO]  systemd: Creating service file /etc/systemd/system/k3s.service
[INFO]  systemd: Enabling k3s unit
Created symlink /etc/systemd/system/multi-user.target.wants/k3s.service → /etc/systemd/system/k3s.service.
[INFO]  systemd: Starting k3s
Result: [INFO]  Finding release for channel stable
[INFO]  Using v1.26.3+k3s1 as release
[INFO]  Downloading hash https://github.com/k3s-io/k3s/releases/download/v1.26.3+k3s1/sha256sum-amd64.txt
[INFO]  Downloading binary https://github.com/k3s-io/k3s/releases/download/v1.26.3+k3s1/k3s
[INFO]  Verifying binary download
[INFO]  Installing k3s to /usr/local/bin/k3s
[INFO]  Skipping installation of SELinux RPM
[INFO]  Creating /usr/local/bin/kubectl symlink to k3s
[INFO]  Creating /usr/local/bin/crictl symlink to k3s
[INFO]  Creating /usr/local/bin/ctr symlink to k3s
[INFO]  Creating killall script /usr/local/bin/k3s-killall.sh
[INFO]  Creating uninstall script /usr/local/bin/k3s-uninstall.sh
[INFO]  env: Creating environment file /etc/systemd/system/k3s.service.env
[INFO]  systemd: Creating service file /etc/systemd/system/k3s.service
[INFO]  systemd: Enabling k3s unit
[INFO]  systemd: Starting k3s
 Created symlink /etc/systemd/system/multi-user.target.wants/k3s.service → /etc/systemd/system/k3s.service.

Saving file to: /home/jesusmarin.dev/config.k3s-server.yaml

# Test your cluster with:
export KUBECONFIG=/home/jesusmarin.dev/config.k3s-server.yaml
kubectl config use-context default
kubectl get node -o wide

🐳 k3sup needs your support: https://github.com/sponsors/alexellis
```
Las últimas líneas bajo `# Test your cluster with:` son importantes dado que 
debemos indicarle a **kubectl** la ubicación del archivo de configuración para 
acceder al nuevo clúster. Por lo que ejecutamos:

```sh
export KUBECONFIG=/home/jesusmarin.dev/config.k3s-server.yaml
```
Como prueba, podemos verificar la lista de nodos de nuestro clúster:

```sh
kubectl get node --all-namespaces -o wide
```
Deberíamos ver algo como:
```sh
NAME         STATUS   ROLES                  AGE   VERSION        INTERNAL-IP     EXTERNAL-IP   OS-IMAGE                         KERNEL-VERSION    CONTAINER-RUNTIME
k3s-master   Ready    control-plane,master   28m   v1.26.3+k3s1   5.161.228.127   <none>        Debian GNU/Linux 11 (bullseye)   5.10.0-21-amd64   containerd://1.6.19-k3s1
```
He aquí el primer nodo del clúster, este es el control plane o nodo master, el cual 
se encarga de administrar los nodos worker.

Hablando de nodos worker, no tenemos ninguno, vamos a crear un par. 

## Creando los nodos worker
Para crear el primer nodo worker tan solo debemos ejecutar el comando:

```sh
k3sup join --ip=5.161.228.177 --user=root --server-ip=5.161.228.127 --server-user=root --k3s-channel=stable
```
Este comando es muy similar al anterior, la única diferencia es que indicamos a 
**k3sup** el comando `join` para indicar que queremos integrar un nodo al clúster y 
el flag `--server-ip` para indicar que la IP del control plane o nodo master.

Una vez ejecutado el comando deberíamos ver algo como:

```sh
Running: k3sup join
Server IP: 5.161.228.127
K1011ef7e69dfd760232ab1554aeb37a78b47b8cce4c7b4e3f0ab43ff7b30e08202::server:60406e81583e25c6eefd51423c344f36
[INFO]  Finding release for channel stable
[INFO]  Using v1.26.3+k3s1 as release
[INFO]  Downloading hash https://github.com/k3s-io/k3s/releases/download/v1.26.3+k3s1/sha256sum-amd64.txt
[INFO]  Downloading binary https://github.com/k3s-io/k3s/releases/download/v1.26.3+k3s1/k3s
[INFO]  Verifying binary download
[INFO]  Installing k3s to /usr/local/bin/k3s
[INFO]  Skipping installation of SELinux RPM
[INFO]  Creating /usr/local/bin/kubectl symlink to k3s
[INFO]  Creating /usr/local/bin/crictl symlink to k3s
[INFO]  Creating /usr/local/bin/ctr symlink to k3s
[INFO]  Creating killall script /usr/local/bin/k3s-killall.sh
[INFO]  Creating uninstall script /usr/local/bin/k3s-agent-uninstall.sh
[INFO]  env: Creating environment file /etc/systemd/system/k3s-agent.service.env
[INFO]  systemd: Creating service file /etc/systemd/system/k3s-agent.service
[INFO]  systemd: Enabling k3s-agent unit
Created symlink /etc/systemd/system/multi-user.target.wants/k3s-agent.service → /etc/systemd/system/k3s-agent.service.
[INFO]  systemd: Starting k3s-agent
Logs: Created symlink /etc/systemd/system/multi-user.target.wants/k3s-agent.service → /etc/systemd/system/k3s-agent.service.
Output: [INFO]  Finding release for channel stable
[INFO]  Using v1.26.3+k3s1 as release
[INFO]  Downloading hash https://github.com/k3s-io/k3s/releases/download/v1.26.3+k3s1/sha256sum-amd64.txt
[INFO]  Downloading binary https://github.com/k3s-io/k3s/releases/download/v1.26.3+k3s1/k3s
[INFO]  Verifying binary download
[INFO]  Installing k3s to /usr/local/bin/k3s
[INFO]  Skipping installation of SELinux RPM
[INFO]  Creating /usr/local/bin/kubectl symlink to k3s
[INFO]  Creating /usr/local/bin/crictl symlink to k3s
[INFO]  Creating /usr/local/bin/ctr symlink to k3s
[INFO]  Creating killall script /usr/local/bin/k3s-killall.sh
[INFO]  Creating uninstall script /usr/local/bin/k3s-agent-uninstall.sh
[INFO]  env: Creating environment file /etc/systemd/system/k3s-agent.service.env
[INFO]  systemd: Creating service file /etc/systemd/system/k3s-agent.service
[INFO]  systemd: Enabling k3s-agent unit
[INFO]  systemd: Starting k3s-agent
```
Podemos realizar una comprobación rápida listando los nodos:

```sh
kubectl get node --all-namespaces -o wide

NAME         STATUS   ROLES                  AGE     VERSION        INTERNAL-IP     EXTERNAL-IP   OS-IMAGE                         KERNEL-VERSION    CONTAINER-RUNTIME
k3s-node1    Ready    <none>                 4m30s   v1.26.3+k3s1   5.161.228.177   <none>        Debian GNU/Linux 11 (bullseye)   5.10.0-21-amd64   containerd://1.6.19-k3s1
k3s-master   Ready    control-plane,master   51m     v1.26.3+k3s1   5.161.228.127   <none>        Debian GNU/Linux 11 (bullseye)   5.10.0-21-amd64   containerd://1.6.19-k3s1
```

Sí, ejecutamos el mismo comando con el tercer y último nodo, cambiándole solamente la IP 
correspondiente en dicho comando, habremos agregado el último nodo.

```sh
k3sup join --ip=5.161.228.178 --user=root --server-ip=5.161.228.127 --server-user=root --k3s-channel=stable
```
Comprobamos nuevamente:

```sh
kubectl get node --all-namespaces -o wide

NAME         STATUS   ROLES                  AGE   VERSION        INTERNAL-IP     EXTERNAL-IP   OS-IMAGE                         KERNEL-VERSION    CONTAINER-RUNTIME
k3s-node1    Ready    <none>                 50m   v1.26.3+k3s1   5.161.228.177   <none>        Debian GNU/Linux 11 (bullseye)   5.10.0-21-amd64   containerd://1.6.19-k3s1
k3s-node2    Ready    <none>                 42m   v1.26.3+k3s1   5.161.228.178   <none>        Debian GNU/Linux 11 (bullseye)   5.10.0-21-amd64   containerd://1.6.19-k3s1
k3s-master   Ready    control-plane,master   97m   v1.26.3+k3s1   5.161.228.127   <none>        Debian GNU/Linux 11 (bullseye)   5.10.0-21-amd64   containerd://1.6.19-k3s1
```
Podemos observar que tenemos todos los nodos con **STATUS** `Ready` y están 
nuestros dos nuevos nodos worker que aparecen con **ROLES** `<none>`.

Con esto, habremos creado el clúster Kubernetes con **K3s** y **K3sup**.

# Prueba del clúster con una app

Ya que se tiene un clúster nuevo, sería buena idea probarlo con alguna app. En 
mi caso haré la prueba con la app Rails 
[ImageStorage](https://github.com/jesusangelm/imagestorage) que use en mi anterior 
artículo [Desplegando una app Rails en Kubernetes](https://jesusmarin.dev/blog/desplegando-rails-app-en-kubernetes).

Los pasos a seguir son prácticamente los mismos que en el artículo anterior, por lo que 
Acá tan solo los resumiré brevemente. Es buena idea que leas el artículo anterior si 
te sientes un poco perdido a partir de acá.

## Preparativos iniciales

Dado que al instalar **K3s** con **K3sup** le pase un flag a **K3s** para deshabilitar
traefik, el clúster actualmente no tiene un **Ingress controller** o **API gateway**.
Esto lo hice de forma intencional para poder usar [Nginx Ingress Controller](https://kubernetes.github.io/ingress-nginx/deploy/) el cual he agregado al clúster con el comando:

```sh
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.7.0/deploy/static/provider/cloud/deploy.yaml
```

En mi caso y debido a que estoy usando un registro docker privado, debo crear un **secret**
en el clúster:
```sh
kubectl create secret generic regcred --from-file=.dockerconfigjson=/home/tu-usuario/.docker/config.json --type=kubernetes.io/dockerconfigjson

```
Ya con esto tengo los ajustes que yo necesito para poder desplegar mi app Rails en 
el clúster.

## Desplegando una app Rails en el clúster Kubernetes (k3s)
Los manifiestos a usar son exactamente los mismos, por lo que podemos 
dirigirnos en una terminal a la carpeta raíz de la aplicación y ejecutar el comando:

```sh
kubectl apply -f k8s/
```
El cual nos debería mostrar algo como: 

```sh
ingress.networking.k8s.io/ingress-service created
deployment.apps/imagestorage-depl created
```

al cabo de unos segundos podemos verificar el listado de pods para ver 
los nuevos agregados correspondientes a la aplicación

```sh
kubectl get pod -o wide
```
lo cual debería mostrar algo como:
```sh
NAME                                 READY   STATUS    RESTARTS   AGE   IP          NODE         NOMINATED NODE   READINESS GATES
imagestorage-depl-5f79658c65-2klfb   1/1     Running   0          2m    10.42.2.5   k3s-node2    <none>           <none>
imagestorage-depl-5f79658c65-2d6h2   1/1     Running   0          2m    10.42.0.6   k3s-master   <none>           <none>
imagestorage-depl-5f79658c65-nnjn7   1/1     Running   0          2m    10.42.1.4   k3s-node1    <none>           <none>
```

Bien, acá vemos que el clúster Kubernetes creado desde cero con K3s está ejecutando con 
Éxito 3 instancias de la aplicación, una en cada nodo tal como se especifica en el manifiesto.

Tan solo necesitamos la IP para poder acceder al servicio:

```sh
kubectl get ingress

NAME              CLASS    HOSTS   ADDRESS         PORTS   AGE
ingress-service   <none>   *       5.161.228.178   80      58m
```
En mi caso el ingress tomo la IP del segundo nodo worker, abrimos dicha IP en un navegador:


![Imagestorage en cluster kubernetes K3s](https://cdn.is.jesusmarin.dev/rails/active_storage/blobs/proxy/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaEpJaWxoWldSaE0yVXlNaTFoTTJRMkxUUXhaVGt0WVRnek1pMDBZall5T1dRMU5tVTBNVGdHT2daRlZBPT0iLCJleHAiOm51bGwsInB1ciI6ImJsb2JfaWQifX0=--3583b0087707255747a56475f85dbf50b278028d/imagestorage-on_k3s-kubernetes-cluster.png)

Podemos ver que la app está ejecutándose correctamente, con esto hemos verificado que la 
app se ejecuta sin problemas en el clúster Kubernetes creado con **K3s**

**NOTA:** Si leíste el artículo anterior, sabrás que esta app usa una base de datos PostgreSQL.
Para que la app funcione al 100% la BD es requerida, pero Hetzner no dispone de bases de 
datos administrados. Por lo que si quieres ver la app corriendo al 100%, puedes probar con:

- Crear el clúster en un proveedor de hosting que ofrezca BD administradas 
**(recomendado para producción)**.
- Crear en el clúster un Pod y un servicio PostgreSQL para ser usado por la app 
**(No recomendado para producción)**.

He excluido la explicación de este detalle, debido a que la meta de este artículo es 
tan solo describir la creación de un clúster Kubernetes con **K3s** y **K3sup**

# Conclusión

Como había comentado en el artículo anterior [Desplegando una app Rails en Kubernetes](https://jesusmarin.dev/blog/desplegando-rails-app-en-kubernetes), Cuando Kubernetes salió al público,
una de las primeras cosas que intente hacer fue justamente crear un clúster desde cero con 
Múltiples vps de los que disponía; sin embargo, esta se convirtió un toda una odisea.

Hoy en día hay muchas formas de obtener un clúster kubernetes, ya sea administrado y todo 
listo para usar, o crearlo desde cero con la ayuda de herramientas como **K3s** y **K3sup** la 
cuál facilitan enormemente la tarea.

Lo descrito acá es tan solo una demostración de las bondades de usar estas herramientas 
y de crear un clúster kubernetes con las máquinas que deseamos, como mencione más arriba
se podrían usar incluso unas cuantas Raspberry Pi y así tener un cluster local para 
desarrollo y pruebas. Otra ventaja es simplemente poder elegir el proveedor VPS que 
deseas y no estar atado a un solo proveedor o una sola infraestructura.


