# Las Reglas de la Ficha

*Documento técnico de reglas — contrato del motor de juego (Fase 1). Cualquier ambigüedad de implementación debe resolverse consultando este documento, no asumiendo.*

## Setup

- 28 fichas, valores de 0 a 6 en cada extremo (incluye las 7 mulas/dobles: 0-0 a 6-6).
- 4 jugadores, asientos 1-2-3-4. Equipos: **1+3 vs 2+4** (compañeros sentados enfrente, no al lado).
- Reparto: 7 fichas por jugador, se reparten las 28 completas (no hay pozo/robo).
- Turno avanza **a la derecha del salidor, en contra del reloj**.

## Determinar quién sale

- **Primera partida de la sesión:** se hace "la sopa" (se revuelven todas las fichas boca abajo) y cada quien levanta su mano al azar. Sale quien levantó la mula de 6-6.
- **Partidas siguientes:** sale el equipo que ganó la partida anterior.
  - El equipo **perdedor** hace la sopa (revuelve las fichas).
  - El equipo **ganador** levanta/escoge sus 7 fichas primero.
  - El equipo ganador decide cuál de los dos compañeros pone la ficha de salida. Esta decisión se puede tomar **en voz alta y abiertamente frente al rival** (ej. "¿sales o salgo?"/"sal tú"). Lo que no se vale es comunicarlo mediante gestos, ademanes o señales no verbales que den información sobre qué fichas tiene cada quien o con qué número convendría o no salir — la pregunta y respuesta en sí son públicas, la lógica detrás de la decisión no se puede señalar de forma encubierta.

## Jugada legal

- Se puede colocar una ficha en cualquiera de los dos extremos abiertos de la fila, siempre que uno de sus valores coincida con el valor expuesto en ese extremo.
- Si un jugador no tiene ninguna ficha jugable, **debe declarar "paso" explícitamente** — no es un salto silencioso/automático del turno.

### Requisito de diseño — ayuda visual de jugadas legales (depende del modo)

Este comportamiento **varía según el modo de juego**:

- **Modo aprendizaje/principiante:** sí se permite ayuda visual — resaltar fichas jugables, sugerir cuándo no hay jugada disponible, o incluso ofrecer pase asistido. El objetivo de este modo es enseñar, no evaluar habilidad.
- **Modo normal y avanzado:** la app **no debe indicarle al jugador humano** de forma preventiva cuáles fichas son jugables o no (nada de resaltar, atenuar/grisar, o filtrar fichas jugables antes de que el jugador actúe). El jugador debe:
  - Revisar su propia mano y la mesa, y decidir si tiene jugada.
  - Presionar activamente un botón de **"Pasar"** si decide que no tiene jugada — no hay paso automático ni sugerido por el sistema.

El motor sí valida internamente la legalidad de la jugada en dos momentos, **en cualquier modo**:
- Si el jugador intenta colocar una ficha que no calza en el extremo elegido → la ficha se muestra brevemente (unos segundos) en la mesa, visible para todos los jugadores, tal como pasaría en una mesa física antes de darse cuenta del error — luego se regresa a la mano del jugador, quien debe colocar una ficha válida. Este momento genera un **nodo de decisión para el equipo rival**: dado que ya obtuvieron el beneficio de haber visto una de las fichas del jugador, pueden elegir entre (a) reclamar la penalización de 25 puntos por "salida en falso" (ver Penalizaciones), o (b) dejar que la partida continúe sin penalizar, quedándose únicamente con la información vista como ventaja. La decisión es del equipo rival, no automática.
- Si el jugador declara "Pasar" teniendo una ficha jugable disponible → esto es un **pase en falso**, infracción con penalización (ver sección de Penalizaciones abajo), no simplemente una jugada rechazada.

**Modo aprendizaje:** en vez de aplicar la penalización directo, la app debe preguntar de resguardo antes de confirmar el paso — algo como "¿Seguro que quieres pasar?" — para prevenir el error por descuido mientras se construye el hábito de revisar bien la mano.

## Penalizaciones (regla "cantinera")

Estas infracciones son consideradas trampa mayor en juego competitivo porque implican transmitir información ilegal (propia o de la mano) al compañero o filtrarla involuntariamente al rival. La mayoría se penaliza con **+25 puntos automáticos** en contra del equipo infractor, sumados a su acumulado hacia los 100 — con la excepción de "salida en falso", que queda a **discreción del equipo rival** (ver detalle abajo), ya que reclamarla renuncia al beneficio de la información ya vista.

- **Pase en falso:** declarar "paso" teniendo una ficha jugable disponible. Penalización automática.
- **Salida en falso:** mostrar o adelantar una ficha antes de que sea el turno correspondiente, dando información extra al resto de jugadores. **El equipo rival elige** si reclama los 25 puntos o prefiere quedarse solo con la información obtenida (ver nodo de decisión en la sección de Jugada legal).
- **Jugar fuera de turno:** adelantarse a jugar antes de que corresponda (mismo problema: transmite información antes de tiempo). Penalización automática.
- **Enseñar fichas al compañero** (o a cualquier otro jugador) de forma deliberada o por descuido. Penalización automática.
- Cualquier otra acción que implique transmisión de información ilegal entre compañeros o hacia el rival, fuera de lo explícitamente permitido (ver nota sobre "¿sales o salgo?" arriba).

**Modo aprendizaje:** estas penalizaciones pueden suavizarse con confirmaciones preventivas (como la del pase en falso) en vez de aplicar la sanción directa, ya que el objetivo del modo es enseñar, no sancionar.

**Implicación de diseño (Fase 1):** el motor debe modelar estas infracciones como parte del estado del juego, no solo como validaciones de UI — necesita una función que aplique la penalización de 25 puntos al marcador del equipo correspondiente y quede registrada en el historial de la partida (para consistencia con el requisito de registrar metadatos de cierres especiales, ver sección de Bonus).

Motivo: preservar la habilidad real de leer la propia mano rápido, que es parte del juego (ver nota de tempo abajo) en los modos donde se juega en serio — automatizar esto le quita mérito y entrenamiento al jugador. El modo aprendizaje existe precisamente para construir esa habilidad antes de exigirla.

**Implicación de diseño:** el motor necesita exponer la función de "¿tiene jugada legal?" como un servicio que la capa de UI puede consultar o no, según el modo activo — es decir, la lógica de legalidad vive en el motor (Fase 1) pero la decisión de mostrarla o no es una configuración de modo que se resuelve en la interfaz (Fase 3). Anotar esto para no acoplar la UI a la lógica del motor de forma que sea difícil apagar la ayuda después.

### Nota de diseño — señal de tiempo (tempo tell)

Dudar antes de declarar "paso" comunica información no verbal (que el jugador estaba evaluando opciones en vez de no tener nada jugable). Esto es válido/esperado en juego presencial como parte de la lectura del compañero, pero:

- **Fase 2 (IA):** el perfil Máster debería poder usar el tiempo de reacción del jugador humano (si el input lo permite medir) como señal adicional de inferencia, además de leer las jugadas mismas.
- **Fase 2 online (futuro):** en multijugador real, esto se vuelve un vector de trampa (comunicación ilegal por chat/latencia). Si se construye ese modo, considerar normalizar/ocultar tiempos de respuesta entre jugadores para no dar ventaja injusta.

## Fin de partida — dos formas

### 1. Cierre por dominación (normal)

Un jugador coloca su última ficha y se queda sin fichas en mano.

- **Puntuación:** el equipo ganador suma únicamente los puntos (pintas) de las fichas que quedaron en mano del **equipo contrario**. Las fichas del compañero del jugador que cerró NO cuentan.
- Ejemplo: si el jugador A (equipo 1-3) cierra, se cuentan las fichas restantes de los jugadores 2 y 4 (equipo rival). No se cuentan las fichas del jugador 3 (su compañero), aunque le hayan quedado fichas en mano.

### 2. Cierre por tranca (bloqueo)

Ningún jugador puede colocar ficha en ninguno de los dos extremos.

- Se suman los puntos (pintas) de las fichas en mano de **cada equipo completo** (los dos compañeros).
- Gana el equipo con **menor suma**.
- **Empate:** gana el equipo que tenía la mano (el que salió) en esa partida.

## Empate de marcador — "Se raya"

- **Cuándo ocurre:** cada vez que, después de contabilizar una partida, el marcador acumulado de ambos equipos queda **exactamente igual** (ej. 50-50, 80-80), sin importar el número — no es exclusivo de un valor cercano a 100.
- **Qué pasa:** el marcador de ambos equipos se resetea a cero ("se raya"/se tacha lo acumulado) y la sesión continúa desde 0-0 hacia los 100 de nuevo.
- **Multiplicador:** dado que en la versión de app no hay apuesta real, se representa como un **multiplicador numérico simple** que la app lleva como registro visible para el usuario (ej. "x2"), sin procesar pagos ni dinero real. Cada vez que ocurre un nuevo empate/"rayada" en la misma sesión, el multiplicador se acumula (ej. si vuelve a empatarse después de la primera rayada, pasaría a "x4"). *(Asunción a confirmar: si el multiplicador debe duplicarse acumulativamente en cada rayada sucesiva, o mantenerse fijo en "x2" sin importar cuántas veces ocurra — avisar si es distinto.)*
- El multiplicador es solo informativo/cosmético en esta versión — no afecta el cálculo real de puntos para determinar quién llega a 100, solo se muestra como contexto cultural del juego.

**Implicación de diseño (Fase 1):** el motor debe revisar el empate exacto después de actualizar el marcador al final de cada partida, antes de verificar si algún equipo alcanzó los 100. El reseteo a cero ocurre inmediatamente al detectar el empate (no espera a que se llegue a 100 empatado, ya que puede pasar en cualquier valor).

## Puntuación acumulada

- Los puntos ganados en cada partida se acumulan por equipo a lo largo de la sesión.
- Gana el equipo que llegue primero a (o supere) **100 puntos** acumulados.

## Bonus especiales

- **Ninguno actualmente.** No hay puntos extra por cerrar con mula, capicúa (ganar jugando ambos extremos con el mismo número), o dejar sin salida al rival.
- **Reconocimiento cultural (sin efecto en puntuación):** cerrar con una ficha "difícil" (mula, última ficha disponible de un palo agotado, capicúa) se considera informalmente una "humillación amistosa" contra el rival — equivalente a un golazo vs. un gol normal. No afecta el marcador, pero:
  - El motor debe **registrar y clasificar el tipo de cierre** (normal / mula / capicúa / palo agotado) como metadato de cada partida, aunque hoy no tenga efecto en puntos.
  - Motivo: permite en Fase 3 (UI) mostrar reconocimiento visual/textual de estos cierres sin tener que rediseñar el modelo de datos después.

## Mecánica de conteo y probabilidades (aprendizaje + hints)

Contar fichas jugadas y leer la información pública de la mesa (qué números están "agotados", cuántas fichas quedan por bando, puntuación acumulada) es una habilidad central del juego real — determina, por ejemplo, si conviene forzar un cierre o no. Esta capacidad se construye como una **pieza de motor compartida**, no como dos sistemas separados:

- **Núcleo técnico:** un motor de inferencia/probabilidades que calcula, con la información pública disponible (fichas jugadas, pases declarados, mano del jugador), la probabilidad de qué fichas quedan en cada bando. Este es el mismo motor que ya está planeado para el nivel **Experto** de la IA (Fase 2) — construirlo una sola vez y reutilizarlo en dos contextos: como cerebro de la IA y como fuente de datos para enseñar/ayudar al humano.

### Modo aprendizaje — gamificado

- Mini-retos o preguntas contextuales durante la partida (ej. "¿cuántos seises quedan sin jugar?", "¿te conviene cerrar ahora o esperar?"), con recompensa (puntos, rachas, insignias) por responder bien — aprendizaje activo, no un tutorial pasivo de texto.
- El objetivo es que el jugador entrene el mismo tipo de razonamiento que usa el nivel Experto/Máster de la IA, para que eventualmente pueda jugar contra ellos en igualdad de condiciones de lectura del juego.

### Modo avanzado — sistema de hints limitados

- El mismo motor de probabilidades se expone como una **ayuda opcional bajo demanda** (ej. botón "pista"), pero con un **número finito de usos por sesión o por día** — no ilimitado, para no volverlo una muleta permanente y mantener el valor competitivo del modo avanzado.
- El hint podría mostrar algo como la probabilidad estimada de éxito de un cierre, o qué números son más riesgosos de soltar en ese momento — sin jugar la ficha por el usuario, solo informar.

**Implicación de diseño:**
- **Fase 2:** el motor de inferencia probabilística debe diseñarse desde el inicio como un componente independiente y reutilizable (no acoplado exclusivamente a la lógica de decisión de la IA), para poder consultarse también desde el modo aprendizaje/hints.
- **Fase 3 (UI):** necesita pantallas/componentes para las preguntas gamificadas del modo aprendizaje y el botón de hint con contador visible de usos restantes.
- **Fase 4 (persistencia):** el conteo de hints usados por sesión/día requiere guardarse localmente y resetearse según la ventana definida (sesión vs. día calendario — pendiente de decidir cuál).

## Glosario regional (gamificación cultural)

El dominó tiene vocabulario propio que varía por país/región — parte del sabor cultural del juego. Se propone un **glosario dentro de la app**, presentado de forma lúdica (no como manual aburrido), que enseñe estos términos como parte de la experiencia.

**Términos confirmados (semilla inicial, verificados por el líder de proyecto):**

| Término | Región | Significado |
|---|---|---|
| Echar la ficha | México | Jugar/colocar una ficha |
| Palo | — | Conjunto de fichas de un mismo número |
| Tranca | — | Bloqueo, nadie puede jugar |
| Cierre | — | Fin de partida por dominación |
| La güera | México | Mula de ceros (doble 0-0) |
| La pecosa | México | Mula de seis (doble 6-6) |

**Nota de precisión:** antes de agregar más términos de otros países (Caribe, Venezuela, Colombia, España, etc.) al glosario público de la app, conviene **verificarlos con fuentes confiables o hablantes nativos de cada región** — no asumir ni inventar términos, ya que el vocabulario de dominó regional no está bien documentado en fuentes generales de internet y un error aquí sería notorio para jugadores de esa región.

**Implicación de diseño:**
- **Modelo de datos:** el glosario debe vivir como una estructura de datos simple (término, región, significado, quizás ficha/situación asociada), no hardcodeado en la UI, para poder ampliarlo fácilmente sin tocar código de interfaz.
- **Fase 3 (UI):** se puede integrar como parte del modo aprendizaje (ej. "dato curioso" al cerrar con una mula: "¡Cerraste con la pecosa! Así le dicen en México a la mula de 6") o como sección de exploración/glosario independiente.
- Encaja bien con el mismo sistema de gamificación de la sección de conteo/probabilidades — mismo patrón de "aprendizaje divertido integrado al juego", no separado de él.

## Ideas futuras (fuera de alcance actual — NO implementar aún)

- **Modo tipo "Balatro":** variante con bonus/comodines por jugadas especiales (cerrar con mula, capicúa, etc.), pensado como modo alternativo, no como reemplazo de las reglas clásicas. Anotado para evaluar mucho después del lanzamiento v1.

## Pendiente de definir (no bloqueante para Fase 1, pero anotar antes de Fase 2)

- Ninguno identificado por ahora — este documento cubre lo necesario para modelar el motor completo.
