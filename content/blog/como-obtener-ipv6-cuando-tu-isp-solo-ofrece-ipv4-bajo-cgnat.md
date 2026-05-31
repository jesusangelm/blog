+++
title = "Cómo obtener IPv6 si tu ISP solo ofrece IPv4 bajo CGNAT"
date = 2026-05-31
draft = false
tags = ['ipv6', 'ipv4', 'cgnat', 'wireguard']
description = "Obten IPv6 para los equipos de tu red cuando tu ISP solo te ofrece IPv4."
+++


Desde que adquirí mi primera Raspberry Pi por allá en el 2016 para crear mi propio NAS casero con un disco duro de 2TB, me quedé enganchado con el mundo del self-hosting. Desde ese entonces ya ha pasado mucho tiempo y el intentar alojar aplicaciones en mi propia red ha hecho que aprenda por mi cuenta cómo funciona realmente internet y también cómo funcionan las redes.

Una de las cosas que son como la piedra en el camino al momento de alojar tus propios servicios en tu red es cómo hacerlos accesibles a internet. Esto se debe a que, si tienes internet residencial por fibra, es cada vez más común que tu ISP te entregue una sola dirección IPv4 compartida tras CGNAT y ninguna dirección IPv6. Esto tiene dos consecuencias graves:

1. Tus dispositivos no son accesibles desde internet **sin trucos** (el port forwarding no existe si no tienes IP pública real).
2. No puedes conectarte a servicios o dispositivos que **solo tienen IPv6** (¿algún proveedor VPS te da descuento si usas un VPS con solo IPv6? pues no lo puedes conectarte a el si solo tienes IPv4).

La solución “correcta” sería que tu ISP te dé una IPv4 pública fija, pero esto puede ser costoso (la última vez que le consulté a mi ISP, me cobraba 10 USD/mes) debido a la escasez de IPv4; además, no todos los ISPs ofrecen esta opción a usuarios residenciales.

La otra solución “correcta” sería que tu ISP habilitara IPv6. Pero de nuevo, muchos no lo ofrecen todavía o se niegan. Así que no toca otra más que ser ingeniosos.

No soy precisamente un experto en redes, pero dado que me gusta aprender por mi cuenta, me he cruzado con muchos artículos, foros de self-hosting y redes sociales en donde a menudo, al indagar sobre las limitaciones como esta, me encontraba con la frase “IPv6 tunneling”.

Al investigar más sobre el tema y con la ayuda de la IA para mejorar y acelerar la investigación, entendí por fin cuál era la solución que podría servirme para lograr la meta de tener IPv6 pública en mi red local.

### La solución: un túnel WireGuard desde un VPS con IPv6

La idea es bastante sencilla:

1. Contratas un **VPS con un prefijo IPv6 ruteado** (mínimo /56, idealmente /48).
2. Creas un **túnel WireGuard** entre ese VPS y tu router doméstico.
3. El VPS reenvía el prefijo IPv6 a través del túnel, y tu router lo distribuye a tus VLANs.

Resultado: **tu red local obtiene direcciones IPv6 globales ruteables** sin que tu ISP haga nada.

Antes de continuar, es bueno que explique mi caso de uso para que lo que viene a continuación tenga más sentido.
Mi router es lo que llaman un Firewall Appliance, básicamente palabras bonitas para una mini PC con muchos puertos de red. Este router ejecuta OPNsense 26 y mi red local consta de alrededor de 8 VLAN IPv4 (privadas, lógicamente) e IPv6 ULA (son similares a las IPv4 privadas de una red local).

También debo destacar que, de momento, mi intención es que solo algunos dispositivos de mi red, más en específico, solo dos de mis VLAN, obtengan IPv6 GUA. Estos dispositivos son básicamente algunos contenedores LXC gestionados por un servidor Proxmox y algunos otros dispositivos en otra VLAN.

---

## Paso 1: Conseguir un VPS con IPv6

Cualquier proveedor que ofrezca prefijo IPv6 ruteado funciona. En mi caso tengo años usando [BuyVM](https://buyvm.net) en Miami el cual ya me ofrece un prefijo IPv6 /48 ruteada sin que se lo pida, pero he escuchado que alternativas como AdvinServers o Clouvider son tambien muy buenas y recomendables.

**Verifica antes de comprar:**

- El VPS tiene al menos una IPv6 activa.
- Tiene un **prefijo ruteado** (por ejemplo `2803:d760:c01::/48`).
- Puede depender del proveedor, pero con BuyVM tuve que asegurarme que la IPv6 del VPS está configurada como **Next Hop Address** para el prefijo ruteado.

En BuyVM todo esto se verifica en el panel de control del proveedor, en la sección de networking. para otros
proveedores puede ser distinto o habria que consultarle a soporte.

## Paso 2: Configurar el VPS

### Paso 2.1: Activar forwarding de paquetes

Crea `/etc/sysctl.d/99-wireguard-forward.conf`:

```sh {linenos=table,anchorlinenos=true}
net.ipv4.ip_forward=1
net.ipv6.conf.all.forwarding=1
net.ipv6.conf.default.forwarding=1
```

Y aplica con `sudo sysctl -p`.

### Paso 2.2: Configurar el firewall con nftables

Necesitas permitir tráfico UDP al puerto de WireGuard y el tráfico ICMPv6 esencial:

```sh {linenos=table,anchorlinenos=true}
#!/usr/sbin/nft -f
flush ruleset

table inet filter {
    chain input {
        type filter hook input priority filter; policy drop;
        iifname "lo" accept
        udp dport 5050 accept          # WireGuard
        icmp type echo-request accept
        icmp type echo-reply accept
        ct state established,related accept
        meta nfproto ipv6 icmpv6 type {
            destination-unreachable, packet-too-big, time-exceeded,
            parameter-problem, echo-reply, echo-request,
            nd-router-solicit, nd-router-advert,
            nd-neighbor-solicit, nd-neighbor-advert
        } accept
        ip6 saddr fe80::/10 icmpv6 type {
            130, 131, 132, 143, 151, 152, 153
        } accept
    }
    chain forward { type filter hook forward priority filter; }
    chain output { type filter hook output priority filter; }
}
```

> **Nota importante:** No necesitas masquerade/NAT. El /48 es un prefijo ruteado, no una dirección compartida.

### Paso 2.3: Instalar WireGuard y generar claves

```bash
apt install wireguard
wg genkey | tee /etc/wireguard/private.key | wg pubkey > /etc/wireguard/public.key
```

Guarda las claves publicas y privadas, las vamos a usar mas adelante.

### Paso 2.4: Crear la configuración de WireGuard

Crea `/etc/wireguard/wg0.conf`:

```ini {linenos=table,anchorlinenos=true}
[Interface]
PrivateKey = <tu_clave_privada>
Address = 2803:d760:c01:0::1/64
ListenPort = 5050

PostUp = nft add table ip6 wireguard
PostUp = nft 'add chain ip6 wireguard forward { type filter hook forward priority 0; policy accept; }'
PostUp = nft add rule ip6 wireguard forward iifname "wg0" accept
PostUp = nft add rule ip6 wireguard forward oifname "wg0" accept
PostDown = nft delete table ip6 wireguard

[Peer]
PublicKey = <clave_publica_del_router> #La generas en Opnsense, paso 3.1
AllowedIPs = 2803:d760:c01::/48
PersistentKeepalive = 25
```

**Divide tu prefijo /48 en /64 por VLAN:**

| Prefijo /64 | Uso |
|---|---|
| `2803:d760:c01:0::/64` | Enlace WireGuard (VPS ↔ Router) |
| `2803:d760:c01:1::/64` | VLAN LAN |
| `2803:d760:c01:2::/64` | VLAN Proxmox |
| `2803:d760:c01:XX::/64` | Cada VLAN adicional |

Activa el túnel:

```bash
systemctl enable --now wg-quick@wg0
```

Recomiendo reiniciar el VPS para verificar que todo arranca automáticamente.

---

## Paso 3: Configurar OPNsense desde tu red local

### Paso 3.1: Crear la instancia WireGuard

Ve a **VPN > WireGuard > Instances** y agrega:

- **Name:** `v6lan` (o el nombre que prefieras)
- **Public Key:** genera una nueva con el icono de engranaje. copiala en el `wg0.conf` del **paso 2.4**
- **Tunnel Address:** `2803:d760:c01:0::2/128`

El resto lo dejamos sin modificar. **Peers** va a sufrir un cambio pero eso sera cuando hayamos creado ya el Peer en el siguiente caso.

### Paso 3.2: Crear el Peer

Ve a **VPN > WireGuard > Peers** y agrega:

- **Name:** `miabuy`
- **PublicKey:** la clave pública del VPS (la que mencione mas arriba que guardaras en el **paso 2.3**)
- **Allowed IPs:** `::/0` (todo el tráfico IPv6 por el túnel)
- **Endpoint address:** la IPv4 pública del VPS
- **Endpoint Port:** `5050`
- **Instances:** Acá elegimos la instancia recientemente creada en el paso anterior, en nuestro caso **v6vlan**
- **Keepalive interval:** `25`

### Paso 3.3: Asignar la interfaz

Ve a **Interfaces > Assignments**, selecciona `wg0` en "Assign a new interface" y dale a **Add**.

Con esto deberíamos poder ver la interfaz en el listado **Interfaces**, seleccionamos la que hemos creado, la habilitamos y dejamos el resto como está. No necesitamos agregar más nada, ya que la configuración de esta interfaz se hace por WireGuard automáticamente.

Regresa a **VPN > WireGuard** y dale a **Enable WireGuard**. Verifica en **Status** que tanto Instance como Peer muestren **UP** (check verde).

### Paso 3.4: Agregar el Gateway IPv6

Ve a **System > Gateways > Configuration** y agrega:

- **Name:** `wg_vps`
- **Interface:** la interfaz WireGuard
- **Address Family:** `IPv6`
- **Priority:** `255`
- **IP Address:** `2803:d760:c01:0::1` (la IP del VPS en el túnel)
- **Upstream Gateway:** habilitado

### Paso 3.5: Asignar prefijos /64 a cada VLAN

Dado que actualmente tengo configurado IPv6 ULA (Unique Local Address) en varias de mis VLANs,
no puedo agregar el prefijo /64 GUA (Global Unicast Address) a la interface de mi Vlan debido a
que ya está configurada con el prefijo /64 ULA. Es por esta razón que debemos agregar
dicho prefijo GUA como **IP virtual**.

Ve a **Interfaces > Virtual IPs > Settings** y agrega por cada VLAN:

- **Mode:** IP Alias
- **Interface:** la VLAN correspondiente
- **Network:** el /64 asignado (ej. `2803:d760:c01:2::1/64`)
- **Description:** algo como: `IPv6 publica desde miabuy para VLAN X`

Repite para cada VLAN que necesite IPv6.

### Paso 3.6: Configurar DNSmasq (RA + SLAAC)

Dado que Opnsense 26 en adelante, por defecto usa Dnsmasq para la gestión DHCP y debido a que ya estoy
usando la función RA de Dnsmasq para las IPv6 ULA, solo necesitaríamos verificar o hacer un
ajuste para que los dispositivos en esta vlan puedan obtener IPv6 GUA del prefijo /64 asignado.

Ve a **Services > Dnsmasq DNS & DHCP > DHCP Range**, selecciona la interfaz de la VLAN y verifica:

- **Start address:** `::1000`
- **End address:** `::fffe`
- **RA mode:** `ra-stateless` + `slaac`

Esto permite que los dispositivos obtengan IPv6 automáticamente.

### Paso 3.7: Reglas de firewall por VLAN

De momento quiero que mis dispositivos con IPv6 GUA puedan acceder a internet con dichas IPv6, pero no quiero que estos dispositivos sean accesibles desde internet mediante estas IPv6.

En **Firewall > Rules [new] > [Tu Interfaz VLAN]**, agrega en orden:

**A) ICMPv6 permitido:**

- **Description:** algo como Permitir Ping ICMPv6 en IPv6 de miabuy
- **Interface:** La interfaz a la cual se aplicara la regla.
- **Action:** Pass
- **Direction:** In
- **Version:** IPv6
- **Protocol:** ICMP
- **ICMP type:** Any
- **Source:** Any
- **Source port:** Any
- **Destination:** Any
- **Destination port:** Any

**B) Salida a internet:**

- **Description:** algo como Permitir salida IPv6 a internet para Vlan X
- **Interface:** La interfaz a la cual se aplicara la regla
- **Action:** Pass
- **Direction:** In
- **Version:** IPv6
- **Protocol:** Any
- **Source:** Pve Network
- **Source port:** Any
- **Destination:** Any
- **Destination port:** Any

**C) Bloqueo entrante por defecto:**

- **Description:** algo como Bloquear IPv6 entrante no solicitado
- **Interface:** La interfaz a la cual se aplicara la regla
- **Action:** Block
- **Direction:** In
- **Version:** IPv6
- **Protocol:** Any
- **Source:** Any
- **Source port:** Any
- **Destination:** Any
- **Destination port:** Any

Si en el futuro quiero exponer un servicio específico de un contenedor (por ejemplo el puerto `443` de un
contenedor con IP`2803:4f10:5:1::abc`), solo se añade en la interfaz **v6lan** (la interfaz Wireguard) una
regla puntual:`Pass IPv6 TCP, destination 2803:4f10:5:1::abc port 443`.

---

## Verificar que funciona

Desde cualquier dispositivo con IPv6 de tu red:

```bash
ip -6 addr show        # Deberías ver la IPv6 asignada
ping6 -c 4 ipv6.google.com  # Verificar conectividad
curl -6 ifconfig.co/json      # Mostrar tu IPv6 pública
```

---

## Conclusión

El resultado es el mismo que si tu ISP te diera IPv6 nativo: **tus dispositivos pueden acceder directamente a internet por IPv6**, sin NAT, sin restricciones de CGNAT. Y lo mejor: tu ISP no tiene nada que ver.

Cabe destacar que como todo, esto tiene sus ventajas y desventajas:

### Ventajas

- **IPv6 nativo en toda la red:** Todas tus VLANs, incluyendo las que no tienen cliente de VPN, obtienen direcciones IPv6 globales (GUA).
- **Sin overhead de encapsulación:** El tráfico es IPv6 real, sin bytes adicionales de túnel.
- **Servicios directamente accesibles:** Puedes exponer servicios web, juegos, cámaras, etc. a internet por IPv6 sin configuraciones complejas.
- **Independencia del ISP:** Tu proveedor de internet no necesita hacer nada. No dependes de su voluntad de habilitar IPv6.
- **Escalable:** El prefijo /48 te da 65,536 subredes /64. Puedes asignar una a cada VLAN, cada dispositivo, o cada servicio.
- **Costo bajo:** Un VPS económico con IPv6 es suficiente. No necesitas infraestructria compleja.
- **Estándar abierto:** WireGuard es un protocolo abierto, auditado y ampliamente adoptado.

### Desventajas

- **Dependencia de un VPS externo:** Si el VPS cae, pierdes IPv6 hasta que se recupere. Necesitas un proveedor confiable con buen uptime.
- **Latencia adicional:** El tráfico que va y viene del VPS añade latencia. Para servicios locales no afecta, pero si expones servicios, el tráfico entra desde el VPS.
- **Tu IPv6 es pública:** Cualquier persona en internet puede hacer ping a tus direcciones. Requiere firewall bien configurado.
- **No resuelve IPv4:** Solo entrega IPv6. Si necesitas IP pública IPv4, esto no ayuda.
- **Configuración inicial compleja:** Requiere conocimientos de redes, routing, firewalls y VPN. No es plug-and-play. Aunque es divertido y aprendes mucho en el proceso.
- **Tu VPS consume ancho de banda del túnel:** Si en algún momento enrutas tráfico general por el túnel (no solo como distribución de prefijo), el ancho de banda del VPS se convierte en cuello de botella.
- **Responsabilidad de seguridad:** Tú eres responsable de configurar correctamente el firewall. Un error puede exponer tu red local innecesariamente.
