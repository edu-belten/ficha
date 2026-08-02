# Ruta Crítica — App de Dominó (Modalidad por Parejas MX/ES)

*Versión: 1.0 — última edición: 2 de agosto, 2026*

**Roles:** Usuario = Líder de proyecto · Claude = Programador
**Objetivo:** App de dominó de 28 fichas (0-6), modalidad 4 jugadores en parejas (asientos 1-3 vs 2-4), juego a 100 puntos, con compañero y rivales controlados por IA de niveles configurables (novato, medio, experto, máster). La IA no ve fichas ajenas: infiere con información pública y con las jugadas del usuario.
**Meta final:** Publicar en App Store y Google Play. Enfoque educativo: aprender desarrollo, GitHub y administración del ciclo de vida completo.
**Meta-objetivo paralelo:** usar este proyecto para aprender a fondo el ecosistema de herramientas de Claude (Claude Code, Design, Cowork/Dispatch, Skills, Artifacts) con uso real conforme cada fase lo requiera — no de forma forzada, sino orgánica.
**Ambición a futuro (fuera de esta ruta):** el dominó es el primer juego de una posible serie. Al líder de proyecto también le interesan los juegos de estrategia estilo "war games" (ej. Risk, Axis & Allies). Vale la pena que el motor de juego y la arquitectura de IA se diseñen con cierta generalidad para que un segundo juego, más adelante, reutilice aprendizajes y no arranque de cero.

**Convención de vocabulario — "Game AI" vs. "Modelo/Agente AI":** en este proyecto, cuando se habla de la IA de los oponentes/compañero (niveles novato/medio/experto/máster, Fase 2), se usa el término **Game AI** — lógica de juego clásica (condicionales, probabilidad, inferencia) escrita en Dart, que corre localmente en el dispositivo sin costo por uso ni llamadas a servicios externos. Esto es distinto de **Modelo/Agente AI** (LLMs tipo Claude/GPT), que sí tendría costo variable y latencia de red, y que se reserva para posibles funcionalidades futuras opcionales (ej. comentarista dinámico, tutor conversacional en modo aprendizaje, apoyo a investigación del glosario regional) — no para el motor de decisión del juego en sí.
**Fase 2 (futuro, fuera de esta ruta):** multijugador en línea.

---

## Fase 0 — Decisiones y cimientos (1-2 semanas)

Objetivo: que ninguna decisión estructural nos frene a media obra.

1. **Elegir stack tecnológico.** Recomendación inicial: **Flutter** (un solo código para iOS y Android, excelente para juegos 2D de tablero, comunidad grande, gratis). Alternativas a evaluar: React Native, Godot. *Decisión del líder de proyecto con recomendación del programador.*
2. **Crear repositorio en GitHub** con estructura de ramas simple (main + ramas por feature). Aquí empieza el aprendizaje de control de versiones: commits, pull requests, issues como lista de tareas del proyecto.
3. **Documento de reglas del juego** (lo escribimos juntos): reglas exactas de la modalidad, quién sale, qué pasa en cierre/tranca, cómo se cuentan puntos, casos especiales. Este documento es el contrato del motor de juego — evita ambigüedades después.
4. **Configurar entorno de desarrollo** en tu computadora (SDK, emuladores). *Tarea del mundo real: instalar y verificar que corre un "hola mundo" en emulador Android y, si tienes Mac, en simulador iOS.*

**Entregable de fase:** repo creado, stack decidido, reglas documentadas, entorno funcionando.

⚠️ **Nota importante:** para publicar en App Store se requiere una Mac (o alternativas como Codemagic/servicios de build en la nube). Confirmar hardware disponible en esta fase, no al final.

---

## Fase 1 — Motor de juego puro (2-3 semanas)

Objetivo: la lógica completa del dominó funcionando **sin interfaz gráfica**, probada con tests automáticos.

1. Modelado de fichas, mano, mesa, turnos, equipos.
2. Reglas de jugada legal, paso obligado, cierre por dominación y por tranca.
3. Conteo de puntos por partida y acumulado a 100.
4. **Tests automáticos** de cada regla (aquí aprendes testing, que es la base de no romper lo que ya funciona).
5. Simulador de partidas en consola: 4 jugadores aleatorios jugando miles de partidas para validar que las reglas nunca se rompen.

**Entregable de fase:** motor que puede jugar partidas completas correctas, con suite de tests en verde. Todo versionado en GitHub con historial limpio.

*Por qué antes que la UI: si el motor está bien probado, la interfaz solo "pinta" lo que el motor dice. Errores de reglas encontrados tarde son carísimos.*

---

## Fase 2 — Inteligencia artificial por niveles (3-4 semanas)

Objetivo: los 4 perfiles de jugador, del más simple al más sofisticado. Esta es la joya técnica del proyecto.

1. **Novato:** juega cualquier ficha legal, preferencia leve por soltar puntos altos. Sin memoria.
2. **Medio:** cuenta fichas jugadas por número, evita quedarse con mulas altas, reconoce cuándo su número está "agotado".
3. **Experto:** inferencia por pases — si un jugador pasó al 5, no tiene cincos; construye un mapa probabilístico de las manos ajenas y juega para ahogar al rival y abrirle camino al compañero.
4. **Máster:** todo lo anterior + lectura de intenciones del compañero humano (¿qué señaló con su salida?, ¿qué número está cargando?), estrategia de equipo explícita (sacrificar puntos propios para que cierre el compañero), y gestión del marcador global (jugar distinto cuando el equipo va 90-40 que 40-90).
5. **Banco de pruebas:** torneos simulados entre niveles para verificar que efectivamente máster > experto > medio > novato en tasa de victorias.

**Entregable de fase:** IA seleccionable por nivel para los 3 asientos no humanos, validada estadísticamente.

*Tarea del mundo real del líder:* jugar tú mismo contra cada nivel y contra jugadores humanos de referencia (familia/amigos dominoeros) para calibrar si el "experto" de verdad se siente experto.

---

## Fase 3 — Interfaz de usuario (3-4 semanas)

Objetivo: que jugarlo se sienta bien, no solo que funcione.

1. Pantalla de juego: mesa, mano propia, indicadores de turno, fichas restantes por jugador, marcador.
2. Animaciones básicas de tiro y revoltura.
3. Configuración de partida: nivel de cada IA, quién es tu compañero.
4. Historial y estadísticas locales (partidas ganadas, promedio de puntos).
5. Pantallas de inicio, ajustes, reglas/tutorial.

*Tarea del mundo real:* definir nombre de la app, ícono e identidad visual (puedes apoyarte en Claude para generar propuestas, pero la decisión y el registro del nombre es tuya). Verificar que el nombre esté disponible en ambas tiendas.

**Entregable de fase:** app jugable de principio a fin en tu teléfono (instalada localmente).

---

## Fase 4 — Pulido y preparación para lanzamiento (2-3 semanas)

1. Sonidos y feedback háptico.
2. Persistencia: reanudar partida a medias, guardar preferencias.
3. Pruebas beta con usuarios reales: **TestFlight** (iOS) y **pruebas internas de Google Play**. *Tarea del mundo real: reclutar 5-10 beta testers entre familia y amigos.*
4. Corrección de bugs reportados.
5. **CI/CD con GitHub Actions:** builds automáticos en cada cambio — aquí entra el aprendizaje DevOps prometido, sin necesidad de pagar cloud todavía.

**Entregable de fase:** versión candidata estable, probada por terceros.

---

## Fase 5 — Publicación en tiendas (2-3 semanas, mucha tarea del mundo real)

Tareas casi todas del líder de proyecto, con acompañamiento del programador:

1. **Cuenta Google Play Console** (~25 USD, pago único).
2. **Cuenta Apple Developer Program** (~99 USD/año).
3. **Política de privacidad** publicada en una URL (obligatoria en ambas tiendas, aunque la app no recolecte datos — la redactamos juntos y aquí puede entrar tu primer contacto con hosting/cloud gratuito, ej. GitHub Pages).
4. Fichas de tienda: descripciones, capturas de pantalla por tamaño de dispositivo, video opcional, clasificación de contenido.
5. Envío a revisión, respuesta a observaciones de Apple/Google (es normal que rechacen a la primera; se corrige y se reenvía).
6. **Lanzamiento** 🎉

**Entregable de fase:** app pública y descargable en ambas tiendas.

---

## Fase 6 — Post-lanzamiento (continuo)

1. Monitoreo de crashes y reseñas.
2. Ciclo de actualizaciones: recolectar feedback → issue en GitHub → desarrollo → release.
3. Aprendizaje de analítica básica de tiendas (descargas, retención).
4. **Aquí se abre la puerta a la Fase 2 del producto (multijugador en línea)**, donde entra de lleno el aprendizaje cloud/AWS: servidores, cuentas de usuario, matchmaking, costos.

---

## Resumen de la ruta crítica

```
Fase 0 → Fase 1 → Fase 2 → Fase 3 → Fase 4 → Fase 5 → Fase 6
setup    motor    IA       UI       beta     tiendas  vida real
```

**Dependencias duras:** el motor (F1) bloquea todo lo demás; la IA (F2) puede desarrollarse en paralelo parcial con la UI (F3) una vez estable el motor; las cuentas de desarrollador (F5) conviene abrirlas durante la F4 porque la verificación de identidad de Apple/Google puede tardar días.

**Estimación total con sesiones de 1-2 horas diarias (bloque 4-6pm):** 3.5 a 5 meses para la v1 publicada. El verano alcanza para llegar con motor + IA terminados y UI avanzada.

## Tareas del mundo real del líder de proyecto (resumen)

- [ ] Confirmar acceso a Mac para builds de iOS (Fase 0)
- [ ] Instalar entorno de desarrollo (Fase 0)
- [ ] Validar reglas del juego con jugadores reales (Fase 0-1)
- [ ] Calibrar niveles de IA jugando contra humanos de referencia (Fase 2)
- [ ] Nombre, ícono e identidad de la app + verificar disponibilidad (Fase 3)
- [ ] Reclutar beta testers (Fase 4)
- [ ] Abrir cuentas de desarrollador Apple y Google (Fase 4-5)
- [ ] Publicar política de privacidad (Fase 5)
- [ ] Preparar fichas de tienda: textos y capturas (Fase 5)
