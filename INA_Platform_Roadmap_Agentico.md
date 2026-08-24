# De "análisis con IA" a plataforma agéntica — hoja de ruta para INA Platform

## 1. Qué cambia conceptualmente

Hoy `api/analyze-project.js` hace **una llamada** al modelo: arma un prompt con el texto del proyecto y los documentos adjuntos, pide un JSON con puntajes y lo guarda. Es IA generativa aplicada una vez, sin memoria entre llamadas, sin capacidad de decidir qué información le falta ni de ir a buscarla, y sin ningún tipo de acción posterior — solo un veredicto.

Una plataforma **agéntica** invierte esa lógica: en vez de "acá tenés todo el contexto, dame un resultado", el modelo opera en un **loop** — observa, decide qué herramienta necesita, la ejecuta, mira el resultado, decide el siguiente paso — hasta completar una tarea de varios pasos sin que un humano tenga que orquestar cada uno. La diferencia práctica no es "un modelo más inteligente", es que el modelo pasa a tener **herramientas** (leer un documento puntual, consultar una fuente externa, guardar un dato, marcar un estado) y **autonomía acotada** para encadenarlas.

## 2. Dónde tiene sentido en esta plataforma específica

Priorizado por relación esfuerzo/impacto, no por orden cronológico obligatorio.

**Agente de intake documental.** Hoy el owner carga a mano `total_hogares`, `accesos_fibra`, `velocidad_actual_mbps`, etc. en `fsu-scoring.html`, y por separado sube la Carpeta Técnica en PDF. Un agente con acceso a `list_documents`/`read_document` podría leer esos PDFs, extraer esos mismos valores y **proponer** el formulario ya completado (el humano confirma o corrige antes de guardar). Es la extensión más natural de lo que `api/analyze-project.js` ya hace — ya lee PDFs con Claude nativamente — solo que en vez de devolver un puntaje devuelve campos estructurados con nivel de confianza por campo.

**Verificación de elegibilidad/compliance.** Los templates FATIC (`CAPITAL_MARKETS_TEMPLATE`, `TASU_TEMPLATE`, `FATIC_GENERAL_TEMPLATE` en `platform.js`) codifican reglas de exclusión bastante específicas: track record de 2 años, sin deudas con ENACOM/ARCA, sectores excluidos, tope de garantía, etc. Un agente que lea el proyecto + documentos y contraste explícitamente contra esa checklist (en vez de un puntaje genérico 0-100) le da al advisor algo mucho más accionable: "falta constancia de 2 años de antigüedad", no "financial_robustness: 45/100".

**Copiloto conversacional por proyecto.** Un panel de chat en `project.html`, con acceso de solo-lectura a ese proyecto puntual (descripción, documentos, `framework_analysis`, `fsu_scoring`, historial de workflow) para que el advisor pregunte "¿por qué bajó el puntaje de este dimension?" o "resumime los riesgos ambientales" sin tener que releer todo. Es la puerta de entrada más simple a "agéntico" porque no escribe nada — solo lee y responde — así que el riesgo de gobernanza es mínimo.

**Enriquecimiento con datos externos.** El criterio de "Baja Penetración de Fibra" en el FSU Scoring depende de Datos Abiertos ENACOM ÷ Censo 2022/INDEC — datos públicos que hoy el usuario tiene que buscar y tipear él mismo. Un agente con una herramienta `fetch_enacom_open_data(localidad)` podría completar ese campo solo, eliminando la fuente de error más obvia del formulario.

**Monitoreo autónomo del workflow.** Un job programado (no disparado por un click) que recorra proyectos en `status='analyzing'` hace más de X horas, o sin movimiento en `project_workflow_events` hace N días, y genere una alerta o incluso un borrador de nota para el advisor asignado. Esto es lo más "agéntico" en el sentido estricto — corre sin que nadie lo llame — pero también lo que menos urgencia tiene hoy dado el volumen.

## 3. Qué cambia en la arquitectura

**El loop de herramientas necesita un orquestador.** Hoy `analyze-project.js` hace un solo `fetch` a la API de Anthropic y listo. Un agente necesita un bucle: llamar al modelo con la lista de tools disponibles, si pide ejecutar una tool correrla server-side y devolverle el resultado, repetir hasta que el modelo devuelva una respuesta final. El **Claude Agent SDK** (con el que está construido este mismo asistente) está pensado exactamente para esto y evita reimplementar el loop a mano; alternativamente se puede armar directo sobre la Messages API con `tool_use`/`tool_result`, que es más manual pero no agrega una dependencia nueva al proyecto.

**El límite de tiempo de Vercel es el cuello de botella real.** `api/analyze-project.js` ya pide `maxDuration: 60` (el máximo del plan Hobby) porque una sola llamada con PDFs grandes puede tardar cerca de eso. Un loop de varios pasos (leer 3 documentos, consultar una API externa, escribir un resultado) fácilmente supera un minuto. Dos caminos, no excluyentes: (a) pasar a Vercel Pro para subir el límite, razonable si el volumen de proyectos es bajo; (b) pasar a un patrón asincrónico — el click dispara un job, un endpoint devuelve "en progreso" al instante, y el frontend hace polling del resultado, exactamente el mismo patrón que `project.html` ya usa hoy para `status==='analyzing'`. Para cualquier agente con más de 2-3 pasos, (b) es la opción robusta.

**Las herramientas tienen que ser funciones acotadas, no acceso a SQL.** Cada tool que el agente puede llamar (`get_project`, `read_document`, `save_fsu_inputs`, `fetch_enacom_open_data`, `log_note`) debe ser una función server-side puntual con el service role key, nunca una consulta abierta. Es el mismo criterio que ya usan `take_project()`/`advance_project_workflow()`: capacidades angostas en vez de un permiso amplio de "escribir lo que sea".

**Cada acción del agente necesita quedar loggeada.** En un organismo regulador, que un sistema haya "decidido" algo sin dejar rastro de qué información usó y por qué es inaceptable. Conviene una tabla nueva (`agent_runs` / `agent_events`, mismo espíritu que `project_workflow_events`) que guarde cada tool call, su resultado y la respuesta final del modelo — no como nice-to-have, como requisito para que esto sea auditable después.

**Nada se guarda solo porque el modelo lo dijo.** Todo lo que hoy es "orientativo, no reemplaza la evaluación de ENACOM" (el disclaimer que ya tiene `fsu-scoring.html`) debería seguir siéndolo con el agente: propone valores, el humano confirma antes de persistir. Esto aplica sobre todo a la verificación de elegibilidad y al intake documental — el copiloto de chat y el monitoreo de workflow, al no escribir datos que afecten una decisión, pueden tener más autonomía sin ese mismo riesgo.

## 4. Orden sugerido

1. **Copiloto de chat de solo lectura** — valida el patrón de tool use con el menor riesgo posible (no escribe nada), reutiliza infraestructura existente (Supabase + Anthropic ya integrados).
2. **Intake documental con confirmación humana** — mayor impacto directo en la carga de trabajo del owner/advisor, construido sobre el mismo código que ya lee PDFs en `analyze-project.js`.
3. **Verificación de elegibilidad estructurada** — reemplaza el puntaje genérico por una checklist accionable contra las reglas reales de cada línea FATIC.
4. **Enriquecimiento con Datos Abiertos ENACOM** — depende de qué tan accesible sea esa API/dataset en la práctica; conviene validarlo antes de comprometerse.
5. **Monitoreo autónomo del workflow** — el que menos urge hoy; tiene más sentido una vez que haya volumen real de proyectos "en tránsito" para justificarlo.

Cada paso es incremental sobre el anterior — no hace falta comprometerse a los cinco para que el primero ya aporte valor.
