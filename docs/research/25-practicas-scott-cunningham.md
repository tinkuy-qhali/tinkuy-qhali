---
item: 25
titulo: Prácticas públicas de Scott Cunningham
modelo: sonnet
esfuerzo: medium
fecha: 2026-10-16
estado: borrador
---
# 25 — Prácticas públicas de Scott Cunningham

## Pregunta
Qué prácticas de trabajo y pedagogía documenta públicamente Scott Cunningham y cuáles conviene adoptar en el agente adversarial de tinkuy-qhali.

## Hallazgos
- El libro (ahora "The Remix", 2.ª edición en curso) enseña con código en R y Stata; su página no menciona Python ni licencia (https://mixtape.scunning.com, 2026-10-16).
- El repo publica datos y programas; hay carpetas R y python y archivos .do/.dta; la licencia concreta no se pudo ver (https://github.com/scunning1975/mixtape, 2026-10-16).
- Mixtape Sessions declara que el material del curso es gratis en su GitHub y que los asistentes reciben slides, app y ejercicios de código (https://www.mixtapesessions.io, 2026-10-16).
- Describe la técnica "creating a devil's advocate": pedir a Claude Code que anticipe fallas de la estrategia (Parte 3, 1-ene-2026, de pago; solo se ve la introducción) (https://causalinf.substack.com/p/claude-code-changes-how-i-work-part, 2026-10-16).
- Su Substack trata agentes de IA en investigación empírica; existen posts sobre dónde ubicar al humano, qué etapas delegar, memoria y hooks ("Don't edit raw data"), pero están tras paywall y no se verificó su contenido (https://causalinf.substack.com/s/claude-code/archive?sort=new, 2026-10-16). **[provisional]**
- Escribir primero como pensamiento, lectura adversarial formal de papers, grupos de lectura y roles de revisión como método propio: **[no verificado]**, sin URL pública hallada; búsqueda en https://causalinf.substack.com (2026-10-16).
- La metáfora "mixtape" y el aprendizaje por repetición: **[no verificado]**; la página de bienvenida no los menciona (https://mixtape.scunning.com, 2026-10-16).

## Decisión propuesta
- Decisión: código ejecutable junto al texto y datos/código públicos con cada informe | Alternativa descartada: texto sin código | Confianza: alta.
- Decisión: adoptar el "devil's advocate" como paso previo a cada informe, materializado en nuestros revisores por rol (métodos, datos, reproducibilidad, legibilidad) | Alternativa descartada: un único revisor general | Confianza: media.
- Decisión: no atribuirle "documentar antes de codificar" ni revisión por roles; se adoptan como principio propio | Alternativa descartada: citarlo como autoridad | Confianza: alta.
- Decisión: no adoptar su paywall ni su modelo de talleres de pago | Alternativa descartada: ninguna | Confianza: alta.

## Riesgos y provisional
- Casi todo lo relevante sobre IA está tras paywall; alguien con suscripción debe verificar los posts de human-in-the-loop, hooks y etapas delegables (Fase 2).
- Licencia del repo sin confirmar.

## Fuentes nuevas
- https://causalinf.substack.com/p/where-and-how-will-the-human-be-in — postura sobre el humano en el ciclo; requiere acceso completo.
- https://causalinf.substack.com/p/which-stages-of-research-production — qué etapas delegar a agentes; requiere acceso completo.
