# Las Reglas de la Ficha

*Versión: 4.0 — última edición: 2 de agosto, 2026*

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

### Regla de orientación de la ficha de salida

Cuando se coloca la ficha de salida (la primera de la partida), el jugador tiene libertad de elegir cuál de sus dos números queda orientado hacia cada lado — a diferencia de cualquier ficha jugada después, cuya orientación queda forzada por el extremo al que se pega. Esa libertad, sin regla, sería una posible vía de señal ilegal (ej. orientar deliberadamente un número hacia el compañero para insinuar que se tienen varias fichas de ese número).

**Regla fija:** el número de **mayor valor** de la ficha de salida siempre se coloca orientado hacia el compañero (el jugador sentado enfrente), sin excepción y sin importar la mano que se tenga. Esto elimina la discrecionalidad y, con ella, la posibilidad de usar la orientación como señal.

- Ejemplo: si la ficha de salida es 3-5, el 5 va hacia el compañero; el 3 queda hacia el lado contrario. Esto aplica siempre, independientemente de qué fichas tenga el jugador en mano.
- Para dobles (ej. 4-4) no aplica distinción, ya que ambos extremos muestran el mismo número.

**Implicación de diseño (Fase 3):** la UI debe calcular automáticamente la orientación correcta de la ficha de salida según esta regla — no debe ser una decisión libre del jugador en la interfaz, ni siquiera visualmente.

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

## Principios tácticos (no son reglas — insumo para diseño de Game AI)

Esta sección **no modifica el motor de reglas** — son principios de estrategia tradicionales del dominó de pareja, documentados aquí porque son el insumo directo para diseñar el comportamiento de los niveles Medio/Experto/Máster de la Game AI en Fase 2. El motor no necesita "saber" estos conceptos por nombre, pero la lógica de decisión de la IA sí debe reflejarlos.

### Las Tres Erres (versión cantinera — la adoptada para este proyecto)

Existe una versión más formal/tradicional (respetar, repetir, recordar), pero para este documento se adopta la **versión cantinera**, más alineada al tono competitivo-amistoso del proyecto:

- **Respetar la mano:** jugar de acuerdo con la salida o la ficha que puso tu compañero, apoyando su estrategia o el palo fuerte que demostró tener.
- **Repite la ficha:** volver a jugar un número o palo que ya jugaste antes, para indicarle a tu compañero que tienes más fichas de ese mismo grupo.
- **"Rechinga" al de al lado:** una vez identificado qué fichas le "duelen" al rival que juega después de ti, seguir explotando eso — poner fichas que no tenga o que lo fuercen a tirar mal, sacándolo de su plan de juego.

### Las Nueve Erres (tácticas reiterables — autor venezolano)

Un desglose más granular de las mismas ideas, en nueve verbos. Referencia consultada: *Domino sin barreras*, Delgado Alvarado, Luis. Editorial C.G.C., Los libros de El Nacional, pág. 74, 2006. Redactado/ilustrado por Oussi.

- **Reconstruir:** rehacer mentalmente cada ficha puesta por el compañero y los adversarios, sobre todo en la primera y segunda ronda.
- **Resolver:** ligado a lo anterior — deducir la mejor jugada posible.
- **Reiterar:** reproducir las propias pintas (jugar del mismo palo propio repetidamente).
- **Repetir:** reiterar las pintas del compañero (mismo concepto que "repite la ficha" arriba).
- **Requerir:** provocar, buscar o "imantar" fichas deseables del resto de la mesa.
- **Respetar:** las pintas propias y las del compañero.
- **Reprimir:** golpear, castigar u obstruir las pintas ajenas (del rival).
- **Renegar:** negar las pintas ajenas — evitar deliberadamente dar fichas que le convengan al rival.
- **Restringir:** anular o sofocar las pintas ajenas mediante jugadas que impidan que el rival las reitere.

**Implicación de diseño (Fase 2):** estos nueve verbos se mapean de forma natural a las capacidades ya planeadas por nivel de IA:
- *Reconstruir/Resolver* → el motor de inferencia probabilística (ya documentado en la sección de conteo/hints), reutilizado como cerebro de decisión del nivel Experto.
- *Reiterar/Repetir/Respetar* → lógica de coordinación con el compañero (relevante sobre todo para el nivel Máster, que debe leer intenciones del compañero humano).
- *Requerir/Reprimir/Renegar/Restringir* → lógica ofensiva contra el rival (evitar darle fichas convenientes, forzarlo a pasar, bloquear sus palos fuertes) — el diferenciador principal entre un nivel Medio (juega bien su propia mano) y un nivel Experto/Máster (juega activamente en contra de la mano ajena).

### Manejo de pintas según el rol — mano vs. seguidor (avanzado)

Este principio **no es regla y no siempre aplica** — se ejecuta solo cuando la mano del jugador lo permite, es decir, cuando tiene margen para elegir entre varias fichas jugables legales. Es una decisión de optimización hacia el marcador acumulado (los 100 puntos), no hacia ganar la partida individual a toda costa.

- **Cuando el equipo tiene la mano (salió):** conviene jugar fichas de valor **bajo** cuando hay alternativa legal. La lógica: mientras más tiempo el rival se quede cargando sus fichas de valor **alto**, más puntos va a sumar el equipo propio si logra cerrar o ganar por tranca — la derrota del rival, si ocurre, vale más.
- **Cuando el equipo es seguidor (no salió, y por tanto tiene estadísticamente más probabilidad de perder esa partida):** conviene jugar fichas de valor **alto** cuando hay alternativa legal. La lógica: al deshacerse pronto de las pintas más pesadas, si el equipo termina perdiendo, la derrota pesa menos puntos hacia el acumulado.

**Implicación de diseño (Fase 2):** este principio requiere que la Game AI (niveles Experto/Máster) evalúe, en cada turno con más de una jugada legal disponible, no solo "¿qué ficha me conviene por posición en la mesa?" sino "¿qué ficha me conviene por rol (mano/seguidor) pensando en el valor de las fichas que me quedan y las del rival?". Es una capa de decisión adicional sobre la lógica básica de jugada legal — se evalúa **después** de filtrar jugadas legales, como criterio de desempate/priorización entre ellas, no como regla de legalidad.

### Cuadrar la ficha del compañero (proactivo — ataque y apoyo a la vez)

Este principio es distinto de "respetar la mano" (que es reactivo — jugar de acuerdo a lo que el compañero ya mostró). Aquí se trata de una jugada **proactiva basada en inferencia**, y tiene un componente ofensivo, no solo de apoyo.

**El mecanismo específico:** cuando se infiere (por fichas jugadas, pases declarados, o lectura de la partida) que el compañero tiene varias fichas de un número determinado (ej. varios "tres"), y ese número ya está expuesto en **uno** de los dos extremos de la mesa, la jugada deseable —cuando la mano lo permite— **no es tapar/cerrar ese extremo**, sino colocar una ficha que haga que el **otro extremo también quede en ese mismo número**. Es decir, "cuadrar la mesa a tres" en ambas puntas.

**Por qué funciona como ataque:** con ambos extremos mostrando el mismo número, el equipo rival necesita tener fichas de ese número específico para poder jugar en cualquiera de las dos puntas — reduce sus jugadas legales posibles a un solo palo, lo cual aumenta considerablemente la probabilidad de que alguno de ellos tenga que pasar. Si el rival pasa, el compañero (que se infiere fuerte en ese número) va a tener una jugada casi garantizada y sin presión en su siguiente turno.

- Es diferente a simplemente seguir el palo que el compañero ya jugó — es anticiparse a lo que probablemente tiene y usarlo para estrechar las opciones del rival, no solo para "dejarle pasar la ficha".
- Requiere el mismo motor de inferencia probabilística ya documentado (sección de conteo/hints) — no es una regla nueva de datos, es un uso adicional de la misma información, ahora aplicado a ambos extremos de la mesa simultáneamente.

**Implicación de diseño (Fase 2):** este es uno de los comportamientos que más separa a un nivel Máster de un Experto — el Experto ya usa el motor de inferencia para jugar contra el rival (bloquear, no regalar), pero el Máster además combina esa misma inferencia con el estado de **ambos extremos de la mesa** para maximizar la probabilidad de pase del rival mientras beneficia al compañero. La lógica de decisión del Máster necesita, entre las jugadas legales disponibles, evaluar explícitamente: "¿existe una jugada que iguale el otro extremo al número que infiero fuerte en mi compañero?" — y priorizarla sobre otras jugadas legales que no tengan ese efecto combinado de ataque + apoyo.

## Refranes y sabiduría tradicional (adaptados a tono MX/Caribe)

Esta sección recoge principios tácticos tradicionales del dominó, expresados como refranes. Los principios de fondo están inspirados en la tradición oral del dominó de mesa (ver fuente abajo), pero **las frases fueron redactadas de nuevo** en tono mexicano/centroamericano/caribeño para el proyecto — no es traducción literal del español ibérico del documento original.

*Fuente de los principios (adaptados, no citados textualmente): Rodríguez Iglesias, David. "Refranes de dominó comentados". Paremia, 11, 2002. Madrid.*

| Dicho (estilo cantinero) | Principio detrás |
|---|---|
| "El que cierra a blancas, cierra con gracia." | Cerrar la partida con fichas de bajo valor (blancas/números bajos) suele favorecer al que cierra — deja poca pinta en la mesa. |
| "Con talento y ojo pelón, ganas ocho de diez — las otras dos son de Dios." | La habilidad importa mucho, pero la suerte sigue siendo un factor real (~40% según la tradición) — ni el mejor jugador gana siempre. |
| "El que cuenta aprisa, cuenta mal." | Contar puntos con descuido lleva a errores frecuentes; la buena cuenta se hace con calma, no de volada. |
| "A la salida del compa, no le busques ni tantito lío." | Jugar acorde a lo que salió tu compañero, respetando el palo que mostró tener, en vez de ir en tu propia onda. |
| "Con cinco o seis del mismo palo, ni Dios te manda a respetar la mano." | Si traes muchas fichas de un mismo número, no estás obligado a seguir ciegamente la salida del compañero — tu palo fuerte manda. |
| "Cuidar al compa es tu chamba número uno." | Ayudar al compañero es la esencia misma del dominó en pareja — más importante que lucirte tú solo. |
| "Doble grande que sale solo, sale caro." | Salir con un doble alto (mula) sin acompañamiento suele ser mala jugada — mejor esperar a tener con qué respaldarlo. |
| "Salida pelada, no te la creas ni truncada." | Si el rival no tapó bien su salida, sospecha — puede ser trampa para hacerte caer. |
| "Al doble se lo cargan de primero, o luego cobra factura." | Los dobles altos conviene soltarlos pronto — si te los quedas cargando, terminan pesándote en la cuenta. |
| "Lo que no repites, no lo pides prestado." | Repetir el palo que ya jugaste (o que jugó tu compañero) le informa qué tienes; hacerlo con orden evita mandar señales contradictorias. |
| "La salida se mata, tengas para matarla o no." | Es casi ley no escrita: hay que intentar anular la salida del rival, aunque sea con lo poquito que tengas. |
| "La ficha que vas a poner, ya la debes traer pensada." | Un buen jugador anticipa mentalmente su jugada antes de que le toque turno, leyendo cómo ha ido la mano. |
| "Al compa se le cuida la jugada, no nomás la propia." | Buscar activamente fichas que le convengan al compañero, no solo pensar en tu mano. |
| "Pensarle mucho a una sola opción es trampa disfrazada." | Dudar cuando en realidad solo tienes una ficha jugable es señal desleal — comunica falsa complejidad al resto de la mesa (ver también la nota de "tempo tell" arriba). |
| "Ficha nueva sin necesidad, es regalo a la mala." | Abrir un palo que nadie ha jugado todavía, sin necesidad, arriesga regalarle fichas fáciles al rival. |
| "Fichas paradas, juego honrado; fichas escondidas, jugada de villano." | Las fichas deben estar siempre visibles para todos en la mesa — ocultarlas (con la mano o de cualquier forma) es trampa, no viveza. |
| "Ahorca el doble seis, que ese sí duele." | Bloquear (dejar sin salida) los dobles más altos del rival es de las jugadas más satisfactorias y efectivas del juego. |
| "El que sale, que mate su propia salida." | Si tú abriste la mano, te conviene poder anular tu propia ficha de salida — no hacerlo es tirar la ventaja. |
| "Repite como gallo en la madrugada, aunque a veces te quedes trabado." | Insistir con el mismo palo presiona al rival de tu derecha a jugar incómodo o pasar, aunque a veces tú mismo te quedes sin jugada por hacerlo. |
| "Nadie manda foto de su mano — ni con gestos, ni de a feo." | Nunca reveles ni ayudes a inferir tu mano fuera de lo permitido (jugadas y respuestas públicas, no señas — ver sección de Penalizaciones). |
| "Para cerrar, saca la cuenta, no la corazonada." | Antes de cerrar, hay que contar: sumar las pintas ya jugadas, restarlas del total de 168 puntos del juego completo, y dividir el resto entre dos — si crees tener más de la mitad de lo que falta, mejor no cerrar. |
| "En los últimos tantos, se juega como chacal — con hambre y con cuidado." | Cerca del final del marcador (cerca de los 100), la atención y el cuidado en cada jugada deben extremarse. |
| "Si al compa le faltan fichas, hasta la mula se sacrifica." | Cuando el compañero es quien trae la mano más corta (menos fichas), vale la pena sacrificar hasta un doble propio para ayudarlo a cerrar. |
| "Jugada forzada no se regaña." | No se le reclama al compañero por una jugada que no tenía de otra — reprochar jugadas obligadas es de mal jugador. |
| "Al que anota, se le checa la cuenta." | Quien lleva el conteo de puntos puede equivocarse (a veces no tan sin querer) — vale la pena que alguien más lleve también su propio registro. |

**Implicación de diseño (Fase 2):** varios de estos refranes son directamente accionables para la Game AI:
- **"Al doble se lo cargan de primero"** y **"ahorca el doble seis"** → lógica de manejo de dobles en los niveles Medio/Experto (soltarlos pronto propios, bloquear los del rival).
- **"Para cerrar, saca la cuenta, no la corazonada"** → fórmula concreta (168 − pintas jugadas, entre dos) que la IA Experto/Máster puede usar como umbral de decisión para intentar cerrar o no. Útil también como pregunta gamificada del modo aprendizaje.
- **"Pensarle mucho a una sola opción es trampa disfrazada"** → refuerza la nota de tempo tell ya documentada; confirma que es un principio tradicional reconocido, no una ocurrencia del proyecto.
- **"Nadie manda foto de su mano"** → refuerza la sección de Penalizaciones ya documentada.

## Distribución física en mesa — "escuadras" (nota de diseño visual, Fase 3)

Esta sección **no afecta la lógica del motor** (Fase 1) — el motor solo necesita conocer los dos valores de los extremos abiertos de la fila, sin importar su representación geométrica. Es una nota de autenticidad visual para cuando se diseñe la interfaz.

- En una mesa física, las fichas no se extienden en línea recta indefinidamente — la mesa (tradicionalmente cuadrada) no tiene espacio. Por convención informal (no es regla fija), cuando la fila alcanza un extremo de la mesa (aproximadamente cada 4-6 fichas), el jugador que tira en ese momento coloca su ficha "en escuadra": gira la dirección de la fila 90°, siempre **en contra de las manecillas del reloj** — el mismo sentido en que avanza el turno.
- Si la fila vuelve a alcanzar otro extremo tras la primera escuadra (unas 3-4 fichas más), se repite el giro en el mismo sentido.
- El propósito es puramente práctico: mantener el juego dentro del alcance físico de todos los jugadores.

**Implicación de diseño (Fase 3):** si se busca una representación visual auténtica de una mesa física, la UI puede simular este comportamiento de "espiral" en vez de una fila recta — pero es una decisión estética, no funcional. El modelo de datos del motor (Fase 1) no necesita saber nada de esto.

## Ideas futuras (fuera de alcance actual — NO implementar aún)

- **Modo tipo "Balatro":** variante con bonus/comodines por jugadas especiales (cerrar con mula, capicúa, etc.), pensado como modo alternativo, no como reemplazo de las reglas clásicas. Anotado para evaluar mucho después del lanzamiento v1.

## Pendiente de definir (no bloqueante para Fase 1, pero anotar antes de Fase 2)

- Ninguno identificado por ahora — este documento cubre lo necesario para modelar el motor completo.
