---
title: "Instalación con agente (Claude Code)"
---

# Instalación asistida por Claude Code

Pega este prompt en Claude Code (en cualquier carpeta de tu PC). El agente verificará qué falta, te pedirá confirmación antes de instalar y te dirá cuándo reiniciar.

```text
Prepara esta PC Windows para trabajar con el repo tinkuy-qhali. Comprueba si están instalados Docker Desktop, Git, GitHub CLI (gh) y Claude Code; para cada uno que falte, propón el comando winget exacto (Docker.DockerDesktop, Git.Git, GitHub.cli) y espera mi confirmación antes de ejecutarlo. Si instalas Docker Desktop, avísame que hace falta reiniciar Windows y activar WSL2 la primera vez que se abra. Después, clona https://github.com/tinkuy-qhali/tinkuy-qhali.git en C:\tinkuy-qhali, ejecuta `gh auth login` si no estoy autenticado, y termina ejecutando start.bat. No instales nada más: R, Python, Julia, DVC y Quarto viven dentro de la imagen Docker.
```

## Qué hace el agente (y por qué)

1. **Verifica antes de instalar** (`where docker git gh claude`): no se instala lo que ya existe.
2. **Pide confirmación por cada paquete** `winget`: una instalación es un cambio del sistema.
3. **Advierte del reinicio**: Docker Desktop necesita WSL2 y un reinicio la primera vez.
4. **Clona y entra**: `start.bat` construye la imagen si falta (20–60 min la primera vez), levanta el contenedor y abre Claude Code dentro. La primera vez, dentro del contenedor, ejecuta `claude login`.

Si prefieres no usar agentes: [`install-manual.md`](install-manual.md).
