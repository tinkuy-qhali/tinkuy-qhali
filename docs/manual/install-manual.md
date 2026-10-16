---
title: "Instalación manual (sin agentes)"
---

# Instalación manual en Windows (una página, seis pasos)

Lo único que vive en tu PC es Docker Desktop, Git, GitHub CLI y Claude Code. R, Python, Julia, DuckDB, DVC y Quarto viven dentro de la imagen.

1. **Instala las cuatro herramientas** (PowerShell como administrador; omite las que ya tengas):

   ```powershell
   winget install -e --id Docker.DockerDesktop
   winget install -e --id Git.Git
   winget install -e --id GitHub.cli
   ```
   Claude Code: sigue https://code.claude.com/docs/en/setup (instalador nativo para Windows).

2. **Reinicia Windows** si instalaste Docker Desktop. Al abrirlo por primera vez, acepta el motor **WSL 2** y espera a que diga "Engine running".

3. **Autentícate en GitHub**: en una terminal, `gh auth login` → GitHub.com → HTTPS → navegador.

4. **Clona el repositorio**:

   ```bat
   git clone https://github.com/tinkuy-qhali/tinkuy-qhali.git C:\tinkuy-qhali
   cd C:\tinkuy-qhali
   ```

5. **Arranca**: `start.bat`. La primera vez construye la imagen (20–60 min según la máquina) y escribe `.env` con los límites de CPU/RAM leídos de Docker. Las siguientes veces entra directo.

6. **Dentro del contenedor**, la primera vez ejecuta `claude login` y sigue el enlace. Listo: ya puedes pedirle al repo sus primeras tres tareas (ver `docs/manual/claude-code.md`, Fase 3).

¿Algo falló? Abre un issue con la plantilla "Error o validador en rojo" pegando la salida exacta.
