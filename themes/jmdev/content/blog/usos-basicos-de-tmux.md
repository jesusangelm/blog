+++
title = "Usos básico de Tmux"
date = 2025-09-12
draft = false
tags = ['tmux', 'sysadmin', 'devops']
description = "Anotaciones de uso básico de Tmux en Linux."
+++

> tmux es un multiplexor de terminales: permite crear, acceder y controlar varios terminales desde una sola pantalla. tmux se puede separar de una pantalla y seguir ejecutándose en segundo plano, para luego volver a conectarse.
{caption="De su repositorio en Github"}

Tmux es muy similar a `screen`, sin embargo, dispone de características que, en mi opinión, hacen su uso más sencillo e intuitivo.

# Instalación

Tmux está disponible en los repositorios de casi cualquier distribución Linux, por lo que su instalación suele limitarse a un solo comando con el gestor de paquetes que corresponda a tu distribución Linux.

En distribuciones basadas en Debian sería solo:
```bash
sudo apt install tmux
```

Luego, simplemente se ejecuta dentro de una terminal con el comando `tmux`.

A continuación, describiré algunas funciones y características de **Tmux** a modo de CheatSheet que me son útiles en el día a día.

# Archivo de configuración en Linux y BSD

Como usuario, para configurar **Tmux**, basta con tener un archivo oculto `.tmux.conf` en la raíz de tu carpeta de usuario. Esto sería `/home/tu_usuario/.tmux.conf`.

# Prefijo Tmux

Tmux, por defecto, usa un comando **prefijo**, el cual es simplemente una combinación de teclas inicial para algunos de sus comandos. Por defecto es `Ctrl-b`, es decir, Tecla **Ctrl** + tecla **b**. Personalmente, me gusta más el prefijo de `screen`, el cual es `Ctrl-a`, por lo que en mi archivo de configuración de Tmux, tengo lo siguiente para indicar dicho cambio:

```sh {linenos=table,anchorlinenos=true}
# .tmux.conf
set -g prefix C-a # prefijo cambiado a Ctrl-a
unbind C-b        # libero el Ctrl-b para poder ser utilizada en cualquier otro comando.
```

# Gestión de ventanas

Las ventanas en Tmux son algo así como las pestañas en emuladores de terminal como Wezterm, Konsole o Terminator, etc. En ellas puedes tener uno o varios paneles.

Comúnmente, cuando abres Tmux sin ningún comando, este probablemente te mostrará por defecto una ventana con un panel donde estará la terminal.

Las ventanas suelen tener nombres y, por defecto, este nombre suele ser el comando en ejecución.

## Comandos de ventanas útiles:

| Comando | Acción |
|---------|--------|
| `Ctrl+a c` | Crear nueva ventana |
| `Ctrl+a n` | Ir a la ventana siguiente |
| `Ctrl+a p` | Ir a la ventana anterior |
| `Ctrl+a 0-9` | Ir a la ventana # (ej.: `Ctrl+a 3` para la ventana 3) |
| `Ctrl+a ,` | Renombrar ventana (ej.: `ssh`, `code`, `logs`) |
| `Ctrl+a &` | Cerrar ventana actual |

# Gestión de Paneles (Panes)

Cada terminal en Tmux pertenece a un panel; estos son las áreas rectangulares donde se muestra el contenido de una terminal en Tmux.

Comúnmente, cuando abres Tmux sin ningún comando, este probablemente te mostrará por defecto una ventana con un panel donde estará la terminal, en esa ventana puedes tener uno o más paneles ya sea dividiendo el existente horizontalmente o verticalmente. Al dividir/agregar paneles, automáticamente tendrás una terminal en el nuevo panel.

## Comandos de paneles útiles:

| Comando | Acción |
|---------|--------|
| `Ctrl+a %` | Dividir ventana **verticalmente** (ej.: código + terminal) |
| `Ctrl+a "` | Dividir ventana **horizontalmente** (ej.: terminal + logs) |
| `Ctrl+a ←/↑/↓/→` | Mover entre paneles |
| `Ctrl+a +` / `Ctrl+a -` | Aumentar/disminuir tamaño del panel |
| `Ctrl+a z` | Maximizar/minimizar el panel actual |
| `Ctrl+a q` | Mostrar números en paneles (presiona el número para saltar) |

# Sesiones

Una sesión en Tmux es algo así como una agrupación de ventanas y paneles. Una de sus funciones más útiles es que estas pueden persistir incluso si cierras la terminal donde estás ejecutando tmux o, si estando conectado a un VPS, cierras la conexión SSH al mismo.

## Comandos de sesiones útiles:

| Comando | Acción | Ejemplo |
|---------|--------|---------|
| `tmux new -s nombre` | Crear una nueva sesión con nombre | `tmux new -s dev` |
| `tmux ls` | Listar todas las sesiones activas | `tmux ls` → `dev: 2 windows (created...)` |
| `tmux a -t nombre` | Adjuntar a una sesión | `tmux a -t dev` |
| `Ctrl+a d` | Te desadjuntas de la sesión actualmente conectada |
| `tmux kill-session -t nombre` | Cerrar una sesión | `tmux kill-session -t prod` |
| `tmux rename-session -t actual nuevo` | Renombrar una sesión | `tmux rename-session -t dev dev-backend` |
| `tmux switch -t otra_session` | Cambias de tu sesión actual a otra sesión existente | `tmux switch -t vps` |

# Conclusión

Tmux es una herramienta muy versátil que en mi caso ha sido muy útil tanto para el desarrollo como para la 
Administración de servidores y vps de forma remota por su facilidad para mantener diversas terminales en ejecución
y persistirlas cuando no se están usando o cuando necesitas dejar alguna aplicación de fondo ejecutando en un servidor.
Si no has usado antes tmux te recomiendo darle una mirada.
