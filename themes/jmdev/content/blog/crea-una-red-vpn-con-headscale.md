+++
title = "Crea una red VPN con Headscale"
date = 2023-05-31
draft = false
tags = ['vpn', 'headscale', 'wireguard']
description = "Instala y configura headscale para crear tu propia red vpn y obtener acceso a tu red local desde internet."
+++
Es muy probable que hayas escuchado o leído en el pasado sobre [Tailscale](https://tailscale.com/),
el servicio basado en wireguard con el que puedes crear una red VPN entre 
tus dispositivos para acceder a recursos remotos de forma segura. 
Pues bien, existe una implementación open-source de su servidor de 
control llamado [Headscale](https://headscale.net/) la cual puedes alojar tu mismo y tener así mayor control 
de tu red vpn.

# Requisitos
Según la documentación oficial, al momento de escribir esto solo especifica que es requerido
tener Ubuntu 20.04 o superior y Debian 11 o superior. No menciona más nada.

En mi caso he dispuesto un VPS con Debian 11, 1 CPU, 1 GB RAM y 20 GB disco NVME.

La documentación no lo menciona, pero para mí es muy importante el agregar un dominio, si lo tienes
crea un subdominio tipo `mired.midominio.tld` o como creas conveniente.

Si deseas utilizar un dominio, este deberá estar apuntando a la IP del VPS o servidor en donde vas a instalar 
Headscale.

# Instalación
La Instalación es sumamente sencilla si se hace con paquetes para el sistema operativo en cuestión.

En mi caso usaré un vps con Debian, Headscale ofrece paquetes `.deb` lo cual lo hace bastante conveniente.
Dichos paquetes se pueden encontrar en su [repositorio GitHub](https://github.com/juanfont/headscale/releases)

También puedes instalar usado contenedores Docker, pero he notado que los desarrolladores hacen énfasis en que 
esa no es la manera en la que ellos lo usan, por lo que no ofrecen soporte para este método y la mayoría
de la documentación proviene de la comunidad. Notarás que es el mismo caso para el uso de Headscale con proxy.

Descargamos el paquete .deb con wget
```sh
# reemplaza VERSION con la ultima version disponible
wget https://github.com/juanfont/headscale/releases/download/VERSION/headscale_VERSION_linux_amd64.deb
```
Una vez descargado, instalamos el paquete:

```sh
# reemplaza VERSION con la version del paquete descargado
sudo dpkg -i headscale_VERSION_linux_amd64.deb
```

Eso es todo, ahora viene la parte divertida.

# Configuración

Cuando realizas la instalación por el paquete del sistema operativo (.deb en este caso)
se genera un archivo de configuración en `/etc/headscale/config.yaml`, vamos a abrir y editar 
este archivo.

Curiosamente, la documentación oficial no habla mucho al respecto, sin embargo, el archivo `config.yaml`
viene cargado con bastantes comentarios que ayudan un poco, veamos los más importantes:

**NOTA:** Los valores que verás a continuación muy probablemente sean muy distintos a los que verás
en tu archivo `config.yaml`. Los valores acá descritos son los que a mi consideración son los valores
ideales para un entorno productivo y los que usaré en mi caso.


## server_url
```yaml
server_url: https://mired.midominio.tld:443
```
Esta es la url que los clientes usaran para acceder al servidor, tanto tu PC como algún 
dispositivo móvil, usará esta URL para acceder al servidor de control Headscale para identificarse o 
compartir configuración.

Headscale y los clientes Tailscale usarán esta URL para generar los enlaces 
requeridos para confirmar y validar un nuevo equipo agregado a la red.

Nótese que en mi ejemplo he cambiado la URL de `http` a `https` y el puerto lo he colocado en el `443`
esto debido a que lo ideal es que estas comunicaciones sean encriptadas para una mayor seguridad.

Si tienes un firewall, lógicamente vas a necesitar abrir el puerto indicado para permitir ese tráfico entrante.

## listen_addr
```yaml
listen_addr: 0.0.0.0:443
```
Acá se le indicará a headscale en qué puerto y el rango de IP se pondrá a escuchar por conexiones entrantes.
Si tienes múltiples IP y solo quieres que escuche por una en específico, puedes colocar acá esa IP.

En este caso headscale escuchará por todas las IP o interfaces y lo hará por el puerto `443`

## grpc_listen_addr

```yaml
grpc_listen_addr: 0.0.0.0:50443
```
Similar a `listen_addr`, pero para comunicaciones gRPC, este recurso sería consumido por algún CLI 
para controlar el servidor Headscale.

## acme_email
```yaml
acme_email: "tu_correo@email.com"
```
Si has usado lets-encrypt, ya sabrás para qué es.

## tls_letsencrypt_hostname
```
tls_letsencrypt_hostname: "mired.midominio.tld"
```
Acá colocas el dominio que deseas usar para tu servidor headscale, este valor 
será usado para solicitar el certificado SSL a lets-encrypt para el dominio especificado.

## tls_letsencrypt_cache_dir

```yaml
tls_letsencrypt_cache_dir: /var/lib/headscale/cache
```
La ubicación de almacenamiento del certificado lets-encrypt y alguno que otro metadata.

## magic_dns
```yaml
magic_dns: true
```
Este valor está bajo el apartado `dns_config`.
Con esto habilitas [MagicDNS](https://tailscale.com/kb/1081/magicdns/), 
el cual te permite acceder a dispositivos por medio de 
un dominio en lugar de una IP.

## base_domain

```yaml
base_domain: mired.midominio.tld
```
Este valor está bajo el apartado `dns_config` y es usado para generar 
los **hostname** para [MagicDNS](https://tailscale.com/kb/1081/magicdns/).
Si por ejemplo agregas a la red un dispositivo llamado `tableta`, podrás acceder
a él mediante `tableta.mired.midominio.tld` cuando estés conectado a la red VPN.

Estas son todos los ajustes que considero hay que modificar para una instalación básica de Headscale.

# Ejecución

Una vez instalado y configurado Headscale, tan solo falta activarlo e iniciarlo, esto lo hacemos con:

```sh
sudo systemctl enable headscale
sudo systemctl start headscale
```

Verificamos que se haya ejecutado correctamente con:

```sh
sudo systemctl status headscale
```

# Creando un usuario

Este usuario va a ser usado al momento de confirmar el registro de un dispositivo en la red
con el servidor de control Headscale.

```sh
sudo headscale users create mi_usuario
```

# Agregando un dispositivo

Ya teniendo listo el servidor Headscale, queda agregar dispositivos a la red,
para esto tan solo tienes que instalar el [cliente Tailscale](https://tailscale.com/download/)
en el dispositivo deseado.

**NOTA:** 
- A partir de acá, cualquier comando que comience por `tailscale` se debe ejecutar en la máquina cliente
ya que `tailscale` es el cliente que se usa para conectarse a la red VPN.

- Cualquier comando iniciado con `headscale` se debe ejecutar en el servidor donde se instaló `headscale`, puesto que 
este es el servidor de control de la red VPN.

Hay dos maneras de registrar una máquina en Headscale, una es mediante un login normal, confirmando el 
dispositivo de lado del servidor y la otra es mediante una llave pre-generada.

En este caso solo explicaré el primer método, ya que es el más parecido a usar el servicio Tailscale.

Para esto tan solo tienes que ejecutar el siguiente comando del cliente Tailscale en la máquina a registrar:

```sh
tailscale up --login-server https://mired.midominio.tld
```

Esto va a generar un enlace en el servidor Headscale, al cargarlo en un navegador, el servidor Headscale te indicará
un comando de confirmación a ejecutar:

```sh
sudo headscale --user mi_usuario nodes registrer --key [LLAVE DEL NODO]
```

En estos dos comandos vemos la importancia de tener el certificado SSL, ya que de lo contrario
toda esta información de autenticación estaría circulando por internet de forma transparente y fácilmente visible
a actores maliciosos.


Una vez agregado un dispositivo, podemos verlo en el servidor de control con:

```sh
sudo headscale node list
```
Deberías ver un listado como este:
```sh
ID | Hostname    | Name               | MachineKey | NodeKey | User  | IP addresses                  | Ephemeral | Last seen           | Expiration          | Online  | Expired
1  | Machine01   | Machine01          | [FFFFF]    | [LLLLL] | user1 | 100.64.0.1, fd7a:115c:a1e0::1 | false     | 2023-05-30 15:12:14 | 0001-01-01 00:00:00 | online  | no
2  | Machine02   | Machine02          | [AAAAA]    | [NNNNN] | user1 | 100.64.0.2, fd7a:115c:a1e0::2 | false     | 2023-05-27 17:05:23 | 0001-01-01 00:00:00 | offline | no
```

# Conectando a tu red local

Uno de los usos muy útiles de una red VPN con Tailscale es la de poder acceder a 
la red local desde el exterior para poder consumir recursos en ella de forma segura.

Con Tailscale es sumamente sencillo y en su mayoría lo haces con tan solo habilitar una función en un nodo desde el panel web.

Con Headscale no tenemos panel web, pero el proceso no es complicado, tan solo
debemos seguir los pasos 1 y 2 de la documentación oficial de [Tailscale](https://tailscale.com/kb/1019/subnets/?q=subnet).

Estos pasos son:

**1) Habilitar IP Forwarding:**

Ejecutando los comandos si tu S.O. Linux tiene la carpeta `/etc/sysctl.d/`

```sh
echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
sudo sysctl -p /etc/sysctl.d/99-tailscale.conf
```

de lo contrario, lo agregas directamente en `sysctl.conf` con los comandos:
```sh
echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.conf
echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p /etc/sysctl.conf
```
**2) Conecta un dispositivo a la red VPN como router de sub-red**

Tan sencillo como agregar un dispositivo a la red con el siguiente comando:

```sh
sudo tailscale up --advertise-routes=192.168.1.0/24 --login-server=https://mired.midominio.tld
```
**NOTA:** Si el dispositivo ya fue agregado a la red VPN previamente, primero deberás desconectarlo con 
```sh
sudo tailscale down
```
y luego ejecutar el comando:

```sh
sudo tailscale up --advertise-routes=192.168.1.0/24 --login-server=https://mired.midominio.tld
```

Nótese que es el mismo comando usado anteriormente para registrar un nuevo dispositivo a la red, la única diferencia es 
el flag `--advertise-routes=192.168.1.0/24`. Acá vas a reemplazar el valor por la IP de sub-red de tu red local.

Muchos routers usan `192.168.1.0/24` por defecto, por lo que este es un buen ejemplo.

Con estos dos pasos, ya tu dispositivo actúa como router de sub-red y anuncia dicha red a la red VPN, pero no está todo listo, ya que 
debemos habilitar dicha red en el servidor de control.

## Habilitando la sub-red

Si en el servidor donde está instalado Headscale ejecutamos:

```sh
sudo headscale routes list
```
veremos algo como:

```sh
ID | Machine   | Prefix         | Advertised | Enabled | Primary
1  | Machine1  | 192.168.1.0/24 | true       | false    | ---
```
Acá vemos que el dispositivo que agregamos a la red con el flag `--advertise-routes` está 
anunciando la sub-red local en la que se encuentra, pero dicha red no está activa, por lo que los 
otros dispositivos desconocen de ella y, por lo tanto, no pueden acceder a ella.

Para habilitarla ejecutamos:

```sh
headscale routes enable -r 1
```

Si ejecutamos nuevamente el comando para listar las rutas, veremos algo como:

```sh
ID | Machine   | Prefix         | Advertised | Enabled | Primary
1  | Machine1  | 192.168.1.0/24 | true       | true    | true
```

Lo cual nos confirma que se ha habilitado la sub-red y en consecuencia los otros dispositivos pueden tener conocimiento de ella.

Sin embargo, esto no quiere decir que desde ya cualquier dispositivo puede acceder a dicha sub-red.

## Habilitar el uso de sub-red en clientes

Una vez agregado un dispositivo como router de sub-red para anunciar tu red local, y una vez habilitada dicha sub-red 
en el servidor de control de la red VPN, tan solo queda habilitar a los otros dispositivos de la red VPN para que 
puedan hacer uso de dicha red y acceder a ella.

Para esto debemos iniciar el cliente Tailscale con el siguiente comando:

```sh
sudo tailscale up --accept-routes=true --login-server https://mired.midominio.tld
```

Con esto, ta deberías poder acceder a la red local desde un dispositivo en el exterior conectado a la red VPN.
Puedes confirmar esto haciendo un ping a cualquier dispositivo dentro de tu red local que responda a ping.

# Conectando un cliente Android

Para conectar a la red VPN desde un dispositivo Android, debemos descargar e instalar el cliente Tailscale en 
dicho dispositivo, una vez realizado esto debemos abrir la aplicación Tailscale y abrir y cerrar el menú tocando el 
icono de tres puntos. Esto lo debes hacer 3 veces hasta que aparezca la opción `Change server`.
Una vez aparezca esta opción, se procederá a colocar la URL del servidor de control Headscale, que en nuestro caso
es `https://mired.midominio.tld`.

Puedes ver un video de este procedimiento en este [PR](https://github.com/tailscale/tailscale-android/pull/55)

Luego de realizar esto, reinicia la app y al abrirla nuevamente inicia sesión de forma regular con la opción `Sign in`,
esto debería abrir el navegador en donde Headscale te indicara el comando de confirmación a ejecutar en el servidor 
donde está instalado Headscale.

# Respaldo

Solo como un detalle aparte, si una vez creada nuestra red, queremos respaldar la configuración del servidor 
de control y el estado del mismo, nada más se necesitaría hacer una copia del archivo `/etc/headscale/config.yaml` y del 
contenido de la carpeta `/var/lib/headscale/`.

Esto es muy útil si se quiere mover el servidor de control a otra máquina sin tener que volver a reconfigurar toda la red.

Si usaste un dominio, tan solo necesitaras cambiar la IP del mismo a la IP del nuevo servidor y los clientes conectados a la red 
VPN ni se van a enterar de que el servidor de control se ha movido a otra máquina dado que todo quedara igual.

Cabe destacar que eso es así de simple si usas sqlite como base de datos, el cual es la base de datos por defecto de Headscale.
Si al contrario, usaste PostgreSQL, entonces deberás hacer un respaldo de la misma y moverla si así lo requiere.

# Conclusión

Si mal no recuerdo, este es un nuevo método de instalación oficial de Headscale, anteriormente solo se disponía de un binario y había que 
realizar más ajustes y configuraciones para tener el servidor funcionando. Con los nuevos paquetes `.deb` la tarea se hace mucho más sencilla.

Hay algunas otras configuraciones interesantes en Headscale muy propias de la forma 
en la que está creada una red Tailscale como lo es el uso de los [DERP](https://tailscale.com/blog/how-tailscale-works/#encrypted-tcp-relays-derp),
pero eso lo comentaré en otra ocasión.

Con todo esto, es muy práctico poder crear toda una red VPN autoalojada y administrada por uno con total control de la misma para 
poder ya sea conectar dispositivos de forma segura o establecer comunicación desde internet con tu red local para poder consumir recursos en ella,
o simplemente usar alguno de los dispositivos en tu red como nodo de salida de internet como si se tratase de una VPN comercial para salir 
a internet con otra IP.



