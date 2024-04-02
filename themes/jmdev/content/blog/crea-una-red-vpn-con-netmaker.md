+++
title = "Crea una red VPN con Netmaker"
date = 2023-02-26
draft = false
tags = ['vpn', 'wireguard', 'netmaker']
description = "Instala y configura netmaker para crear tu propia red vpn y obtener acceso a tu red local desde internet."
+++

> Netmaker es una herramienta para crear y gestionar redes virtuales superpuestas. Si tienes al menos dos máquinas con acceso a Internet que necesitas conectar con un túnel seguro, Netmaker es para ti. Si tienes miles de servidores repartidos por varias ubicaciones, centros de datos o nubes, Netmaker también es para ti. Netmaker conecta máquinas de forma segura, estén donde estén.

Esta de arriba es la explicación oficial de que es Netmaker en su documentación. En pocas 
palabras, Netmaker es una herramienta open-source que podemos alojar en nuestros propios vps 
o servidores de internet, con el fin de poder usarla para conectar de forma segura 
y encriptada todas las máquinas de la que dispongamos, ya sea vps, 
servidor dedicado, contenedores, routers o Raspberry pi entre otros.

# Pre-requisitos

Al momento de escribir esto, los requisitos para instalar Netmaker son:

- VPS o servidor dedicado con ubuntu 22.04 con ip pública y una instalación limpia.
- Puertos abiertos en el firewall: 80, 443 ambos por tcp y el rango del 51821-51830 por udp
- Un dominio (opcional, pero personalmente yo lo recomiendo) con la capacidad de poder configurar un Wilcard dns. Eso es `*.netmaker.tudominio.com`. De no usar dominio propio, netmaker va a generarte uno de forma gratuita mediante un servicio de tercero.
- La máquina donde se instalara Netmaker debe contar con al menos 1 GB de RAM y un CPU

# Instalación

La instalación es sumamente sencilla, tan solo se necesita ejecutar el siguiente
script en la terminal y seguir los pasos del mismo. El script preguntará si deseas usar
tu dominio (que para este punto deberia ya tener el ajuste wildcard DNS apuntando a la IP pública de la máquina) o 
si prefieres usar un dominio autogenerado.

El script también te va a consultar si deseas instalar la versión comunitaria o la versión empresarial de Netmaker.
Para el uso que generalmente le doy a Netmaker, con la versión comunitaria es suficiente y muy probable que también lo sea para ti.

```sh
sudo wget -qO /root/nm-quick-interactive.sh https://raw.githubusercontent.com/gravitl/netmaker/master/scripts/nm-quick-interactive.sh && sudo chmod +x /root/nm-quick-interactive.sh && sudo /root/nm-quick-interactive.sh
```

Más información en https://github.com/gravitl/netmaker#get-started-in-5-minutes

Una vez culminado el proceso de instalación con éxito, podrás acceder al panel en `https://dashboard.netmaker.tudominio.com` y crear tus redes VPN.

![Netmaker Dashboard](https://cdn.is.jesusmarin.dev/rails/active_storage/blobs/proxy/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaEpJaWxoWkRSaU1qVTNNQzFoTTJGaUxUUTBNRFl0WWpJeFlpMWhZMlJpWldVME56aGlPV0VHT2daRlZBPT0iLCJleHAiOm51bGwsInB1ciI6ImJsb2JfaWQifX0=--023d95c2681905e4a4d0f075b14fa83ae661d426/netmaker_dashboard.png)

# Creando una red

Mis conocimientos en redes no son muy buenos, por lo que no entraré en mucho detalles al respecto.

Por defecto, Netmaker podría crearte una red, de lo contrario tú puedes crear tu propia red. O simplemente eliminar la red existente y crear una nueva.

También puedes tener múltiples redes, separadas unas de otras, por lo que puedes dejar la red que netmaker podría ya haber generado o crear una para experimentar.

Para crear la red, tan solo debes:

1. En el `Dashboard`, ir a la sección `Networks`
2. Luego has clic en `Create Network`

Acá verás un formulario en el que lo más importante es el nombre de tu red y el rango IPV4. Como mis conocimientos de redes no son muy buenos, yo uso la opción `Autofill` arriba 
del formulario, esta me genera un nombre de red que puedo cambiar, pero también me genera un rango de IPV4. Este autofill lo puedes clicar las veces
que quieras hasta encontrar un rango que sea de tu conveniencia y que no genere conflictos con otras redes a la que se conecten tus equipos.

Otra opción que podría ser útil es `UDP Hole punching` que sería de utilidad si algún NAT esté bloqueando la comunicación. Dependiendo de tu ISP podría ser necesario o no.

![Crea una red Netmaker](https://cdn.is.jesusmarin.dev/rails/active_storage/blobs/proxy/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaEpJaWxpTUdFNFlUZG1aUzAwTWprMExUUmxORGd0T1dJNFpDMDRaRGt5WW1KaU5tSTRNVFVHT2daRlZBPT0iLCJleHAiOm51bGwsInB1ciI6ImJsb2JfaWQifX0=--68ab3d4d94a787daa99bb15e81964c207e8528d4/create_network-netmaker.png)


# Generando Access Keys

Para agregar máquinas a tu red, primero se requiere que se genere una llave de acceso, la cual se usara como token de autenticación para tus máquinas.
Cabe destacar que se puede especificar cuantas veces se puede usar esta llave de acceso, es decir, si tienes 5 Raspberry PI que quieres agregar a tu red,
puedes crear una llave de acceso con nombre `mis-rpi` y usos `5`.
También es importante saber que el nombre de este `access key` es opcional, puesto que Netmaker puede generarlo, así como también es posible que encontrar
una instalación limpia, Netmaker ya haya creado una llave de acceso con suficientes usos.

Para generar una llave de acceso, tan solo:

1. Nos dirigimos a la opción `Access keys` del `Dashboard`.
2. Una vez allí elegimos la red que acabamos de crear en el paso de arriba o cualquier otra red a la que quieras conectar alguna máquina.
3. Hacemos clic en `Create access key` y especificamos el nombre (opcional) y la cantidad de usos deseada.

Esto nos mostrará la access key y una serie de comandos de ejemplos que podemos usar para conectar una máquina a nuestra red vpn. Notarás también que se muestra algo llamado
`Access token` el cual se usa también para conectar un cliente netmaker (alguna de nuestras máquinas) a la red vpn.

![Crea un access key](https://cdn.is.jesusmarin.dev/rails/active_storage/blobs/proxy/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaEpJaWswTUdKaU9HRmtPQzAxTTJSbUxUUm1aakF0T0RNek5TMHhOV1prWlRRNE9EUXlPR1lHT2daRlZBPT0iLCJleHAiOm51bGwsInB1ciI6ImJsb2JfaWQifX0=--1fb5dbbe208840795f27a50cf314bea26de324ca/netmaker_access-key.png)

Al momento de conectar un equipo a la red VPN, lo ideal sería usar el `access token`, ya que este es un JSON Web token y contiene datos de acceso a nuestro nodo principal Netmaker.

Esta información la puedes ver haciendo clic en el nombre de las access keys ya creadas, el listado que se muestra al entrar en la sección de `Access keys` y luego de elegir la red.

![Lista de access key](https://cdn.is.jesusmarin.dev/rails/active_storage/blobs/proxy/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaEpJaWxsTldabU1qSXlOUzA1T1dabUxUUmpOekl0T0RkaVppMHlObVUyT1RNelptTTBNbUlHT2daRlZBPT0iLCJleHAiOm51bGwsInB1ciI6ImJsb2JfaWQifX0=--8afd46ad451131f9a58ffd46baeb30e84488128a/access_key_list.png)

# Conectando Nodos

Una vez tenemos una `access key`, podemos conectar una máquina a la red vpn. Para esto se necesita instalar un cliente netmaker en dicha máquina que 
quieres conectar a la red.

Netmaker soporta múltiples sistemas operativos y arquitecturas, así como el uso de clientes desde un contenedor docker.
Para una descripción más detallada de instalación del cliente que más te convenga, recomiendo revisar el siguiente enlace: https://docs.netmaker.org/netclient.html
Allí se explica la instalación del cliente en diversas plataformas.

En este ejemplo los nodos fueron un VPS con Debian 64 bits y una Raspberry PI 3 B+ con Raspbian 11

Por lo que para conectar cualquiera de estos dos dispositivos podemos usar el `Join Command` que obtuvimos en el paso anterior
al momento de crear el `access key`

```sh
netclient join -t eyJ7aeg4shoo6suiseeng3aequoo0lee9apaht6Uhex7AqueiVaxii2nu9eQu0aishoon1bai3aeh4ooJufa0eegeeb4udQ==
```

Una vez realizada la conexión con éxito, podremos ver el nodo recién agregado en el listado de nodos haciendo clic en `Nodes` en el `Dashboard`

![Lista de nodos](https://cdn.is.jesusmarin.dev/rails/active_storage/blobs/proxy/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaEpJaWswWVRJM01XRXpPQzAzT1dWa0xUUTFZelV0WVRJM05pMHlNalptWkRrNU5qTmhPV1FHT2daRlZBPT0iLCJleHAiOm51bGwsInB1ciI6ImJsb2JfaWQifX0=--89895498da7c2d56098231ca7c5f2bb4dd7d54b7/node_list.png)

Si inmediatamente probamos la conexion entre los nodos haciendo ping entre ellos mediante su ip de la red vpn, muy probablemente notaras que 
ya hay conexion entre ellos, sin necesidad de hacer ajustes manuales en los nodos existentes. Esto es debido a que Netmaker se encarga de 
administrar los nodos existentes con cualquier ajuste o modificacion que se haga en la red a la que estos pertenecen.

Si agregas un nodo nuevo, los nodos existentes se conectaran a el automaticamente. 
Lo mismo en el caso que cambies una IP de red de algun nodo, los otros nodos obtendran
este cambio y ajustaran sus configuraciones para poder conectarse al nodo de nuevo.

# Tipos de Nodos

En Netmaker un nodo puede jugar diversos roles, entre ellos [Ingress](https://docs.netmaker.org/external-clients.html) y [Egress](https://docs.netmaker.org/egress-gateway.html).

### Ingress node

![Diagrama nodo Ingress](https://cdn.is.jesusmarin.dev/rails/active_storage/blobs/proxy/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaEpJaWxoWXpOaE56a3lNQzFqTW1ZNUxUUmxNekF0T1dNMFppMHlNVGcwT1RrMU4yUmtZbVlHT2daRlZBPT0iLCJleHAiOm51bGwsInB1ciI6ImJsb2JfaWQifX0=--716b5fc986eef03433cd52a121452117c3eda3d4/ingress.png)

Estos permiten a clientes externos conectarse a una red y acceder a los servicios mediante este nodo Ingress.
Estos clientes externos pueden ser cualquier dispositivo que no puedan o no deba ser conectada en malla a la red vpn
como por ejemplo un teléfono, una laptop o una PC.

Hay que tener en cuenta que estos clientes externos son no administrados por Netmaker, por lo que los mismos no puedes obtener los últimos cambios realizados en la red
como por ejemplo conectarse automáticamente a un nuevo nodo agregado o actualizar la IP de la red que se haya cambiado a un nodo en específico.

Es importante aclarar que los Ingress nodes deben tener IP pública y no NAT, para que los clientes externos puedan acceder a este de forma directa por internet.

Por defecto, la red no tendrá ningún Ingress node, pero tú puedes hacer que un nodo existente se comporte como uno dirigiéndote:

1. En el `Dashboard` a `Nodes`, eligiendo la red respectiva
2. Luego haz clic en el icono de la flecha en la columna `Ingress Status` que le corresponde al nodo que deseas.

![Crear nodo Ingress](https://cdn.is.jesusmarin.dev/rails/active_storage/blobs/proxy/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaEpJaWxtTXpCaE1UVmpPUzAxWkRoa0xUUTBORFF0T0RsbU1TMDNObVF6TlRreE5qSXlOemtHT2daRlZBPT0iLCJleHAiOm51bGwsInB1ciI6ImJsb2JfaWQifX0=--cd539aa7ad2f69c9a5d594404279d1afc74924de/set_ingress.png)

### Egress node

![Diagrama nodo Egress](https://cdn.is.jesusmarin.dev/rails/active_storage/blobs/proxy/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaEpJaWt4WWpSbFl6RTJNUzB4TURZNUxUUXhOMlV0WWpCa1ppMW1NbUUzTUdJNVpETTJOV1VHT2daRlZBPT0iLCJleHAiOm51bGwsInB1ciI6ImJsb2JfaWQifX0=--bc1e78c27af6064f4c85adc70f4c4594ebeae6f7/egress.png)

Si quieres acceder a los servicios alojados en tu red local (la de tu casa u oficina), este es él 
tipo de nodo Netmaker que te interesa.

Los Egress node permiten que los otros nodos y/o clientes externos puedan acceder a redes externas,
este tipo de nodos son simplemente clientes Netmaker que han sido desplegados en un servicio o router 
con acceso a esas subredes.

Nuevamente, este es un tipo de configuración de red vpn que es muy utilizado para poder tener acceso a servicios alojados en tu 
red local. Desde internet, sin la necesidad de abrir puertos en tu router o exponer directamente tus equipos a internet.
Lo mejor de todo, el tráfico está encriptado entre los nodos gracias a Wireguard.

Es importante resaltar que para que un nodo pueda hacer función de Egress gateway, este debe:

- Ser un cliente netmaker (no cliente externo).
- Debe tener acceso a la sub-red que se desea anunciar.

De la misma forma como se hizo arriba para agregar un nodo como Ingress node, podemos hacer lo mismo especificar un nodo como Egress node:

1. Haciendo clic en el icono `Create Egress gateway` en el nodo elegido.

![Crear nodo Engress](https://cdn.is.jesusmarin.dev/rails/active_storage/blobs/proxy/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaEpJaWs0WXpJM1ltTTBPUzFoTWpReUxUUmtNamt0T0RSbU5TMDVPVFkzTjJNNVpXWXdZV0VHT2daRlZBPT0iLCJleHAiOm51bGwsInB1ciI6ImJsb2JfaWQifX0=--456e58744fbdd7ab2b34b9e1b8d9befc1507e517/set_egress.png)

2. Luego veremos un formulario adicional donde se nos solicitara el rango de IPV4 al que queremos tener acceso y la interfaz de red que la máquina cliente usa para acceder a esa red.

![Crear nodo Engress - detalles](https://cdn.is.jesusmarin.dev/rails/active_storage/blobs/proxy/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaEpJaWxoT1RNelpEWmlaaTA1Tm1GbUxUUmxZMkl0WVdJd1pDMHhNbVEyWkRKa05UbGpNVEFHT2daRlZBPT0iLCJleHAiOm51bGwsInB1ciI6ImJsb2JfaWQifX0=--8b4db07f486ca688fd356ee4ba3f87ae71842943/set_egress_detail.png)

Un ejemplo: Si tenemos una Raspberry PI como miembro de nuestra red netmaker (cliente netmaker) y conectada a nuestra red local (casa u oficina),
muy probablemente la interfaz que esta RPI usa para conectarse al router local será `eth0`.
También es muy probable que tu router tenga configurado una red con un rango tipo `192.168.8.0/24` o `192.168.1.0/24`, este rango es el que 
colocaremos en el formulario.

Nuevamente, esto es solo un ejemplo y los datos reales dependen de la red que quieras que esté disponible en tu red VPN y la interfaz de red usada por el cliente netmaker 
para acceder a esta red.

Una vez realizado los ajustes con éxito, tus nodos deberían poder tener acceso a la red que acabas de agregar.

# Clientes externos

Hace un momento cuando asignamos un nodo como Ingress gateway, se dijo que estos 
nodos permiten a clientes externos acceder a la red netmaker, pero no mencionamos como. Acá lo vamos a ver.

Los clientes externos manejan una forma de autenticación distinta a los nodos/clientes Netmaker, pero sí 
ya has usado Wireguard en el pasado, notarás que de hecho es así como se conecta un cliente wireguard a su servidor. Y es que 
las credenciales de conexión de los clientes externos son simples configuraciones Wireguard.

Digamos que queremos acceder a nuestra red vpn desde nuestro smartphone, necesitamos crear un cliente externo en netmaker, para esto:

1. Vamos al `Dashboard` y seleccionamos `Ext. Clients`
2. Elegimos la red deseada. Hecho esto veremos dos tablas, una listando los Ingress node (izquierda) y otra listando los clientes externos (derecha).
3. En la tabla de los Ingress node, hacemos clic en el icono `+` bajo la columna `Add External Client` del Ingress node deseado.
4. Veremos que se agregó un nuevo cliente en la tabla `Clients`. Esta es la configuración cliente que usaremos para conectarnos como cliente externo.

![Crear cliente externo](https://cdn.is.jesusmarin.dev/rails/active_storage/blobs/proxy/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaEpJaWs0WVRWbE5XSTFOUzB6TURRMExUUmhNVGt0T0RRNFpTMDNNVGxrTXpnME1EQTRNbVlHT2daRlZBPT0iLCJleHAiOm51bGwsInB1ciI6ImJsb2JfaWQifX0=--db44de675fb09ea257b0b3644d54e45796295859/ext_client.png)

Acá tienes dos opciones para trasladar esa configuración a tu smartphone, la más evidente es haciendo clic en el icono de codigo QR, ya que esto 
despliega justamente un codigo QR válido que puede ser escaneado por ejemplo por la aplicacion [Wireguard for Android](https://f-droid.org/en/packages/com.wireguard.android/).

La otra opción es hacer clic en `Download client configuration` y así importar esa configuración en tu smartphone o PC para que 
se puede conectar a la red VPN.

Como comente antes, los clientes externos son **no administrados** por netmaker, por lo que estos no van a poder enterarse sobre cambios
realizados en la red VPN o sus nodos. Para esto es necesario que descargues la configuración wireguard nuevamente, una vez realizado algún cambio
en la red VPN. No es necesario generar un `External client` nuevo, con descargar otra vez la configuración, es suficiente, ya que está muy probablemente 
haya sido actualizada para reflejar cambios en la red VPN.

# Gráfica de red

Tal vez ya hayas notado que en el `Dashboard` hay una opción llamada `Network Graphs`, también puedes verlo como la opción `GRAPH` cuando ves 
los detalles de una red existente.

Esta opción lo que permite es simplemente visualizar una representación gráfica de nuestra red VPN, en esta se observa los distintos
nodos agregados a la misma, los clientes externos y las redes externas disponibles a través de los Egress node.
Es muy útil para entender como hemos conformado nuestra red VPN y los elementos en ella.

![Grafica de red](https://cdn.is.jesusmarin.dev/rails/active_storage/blobs/proxy/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaEpJaWszTkdaak0yVmpZaTFpT0RNNExUUTJaalV0T1RRNU5pMDJZemRoWWpRek56TXlZV01HT2daRlZBPT0iLCJleHAiOm51bGwsInB1ciI6ImJsb2JfaWQifX0=--47f5b58e7095816da30ba982f525de1fb1e75d01/network_graph.png)

# Conclusión

Hay muchas otras funciones y ajustes que ofrece Netmaker, pero describirlas acá, haría esto mucho más extenso, para más detalles recomiendo leer la documentación oficial.

Con todo esto ya podremos tener nuestra propia red vpn encriptada con wireguard y configurada para poder acceder desde el exterior a 
nuestra red interna.
Colocando un servidor web en una configuración de proxy inverso podríamos ser capaces de acceder mediante un dominio a servicios que tengamos
autoalojados en nuestro hogar. Para el momento de escribir este artículo, ese es el modo en el que este blog está alojado, en una Raspberry pi en mi casa.

