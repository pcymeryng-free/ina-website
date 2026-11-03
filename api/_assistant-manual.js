/**
 * INA Platform — knowledge base for the platform assistant (api/_assistant.js).
 *
 * The user manual (Manual_Usuario_Plataforma_INA.pdf, version 25/08/2026)
 * split into its numbered sections, so the assistant's search_manual tool
 * can return only the 2-3 relevant sections per question instead of putting
 * the whole ~35KB manual in every prompt (which alone would blow Groq's
 * free-tier 6,000 tokens/minute budget).
 *
 * Generated from the PDF with `pdftotext` — regenerate whenever the manual
 * is updated. Underscore prefix: Vercel does not turn _-prefixed files in
 * api/ into Serverless Functions, so this does not count against the Hobby
 * plan's 12-function cap.
 */

module.exports = [
  {
    "title": "1. Introducción",
    "text": "La Plataforma INA es la herramienta que ENACOM y los organismos, licenciatarios y cooperativas de\nServicios de TIC utilizan para presentar proyectos de infraestructura de conectividad, evaluar su nivel de madurez y recibir recomendaciones concretas de financiamiento. Cada proyecto se evalúa con el Investment\nReadiness Index™ (Índice de Preparación para la Inversión) y el Multilateral Finance Navigator™, dos metodologías propias de INA que traducen la información del proyecto en un puntaje objetivo y en un listado de mecanismos de financiamiento adecuados — desde bancos multilaterales de desarrollo hasta las líneas específicas de ENACOM como el Fondo del Servicio Universal, Créditos a Tasa Subsidiada o Instrumentos de Deuda del Mercado de Capitales.\nEl análisis con IA ya no se ejecuta automáticamente al cargar o editar un proyecto: se dispara manualmente, desde la ficha del proyecto, con la opción Análisis IA del menú Análisis — así tenés control sobre el momento exacto en que se corre (por ejemplo, después de terminar de adjuntar toda la documentación de respaldo).\nVer secciones 5.3 y 5.4.\nAdemás de proyectos individuales, la plataforma permite agrupar iniciativas relacionadas bajo Programas (por ejemplo, un plan provincial que combine cable submarino, backbone de fibra y última milla), armar Hojas de Ruta con seguimiento paso a paso y roles RACI por entidad, llevar una Matriz de Riesgos activa durante la ejecución, y ofrece templates guiados — formularios estructurados basados en resoluciones oficiales de\nENACOM — para que cargar un proyecto o postularse a un programa sea más simple y estandarizado.\nEste manual describe, paso a paso, cómo ingresar a la plataforma, qué puede hacer cada tipo de usuario, y cómo usar cada una de sus secciones: Proyectos, Hojas de Ruta, Matriz de Riesgos, Programas,\nAutoevaluación, FSU Scoring y el Panel de Administración."
  },
  {
    "title": "2.1 Crear una cuenta",
    "text": "Desde international-network-advisors.com/app/register.html completá el formulario de registro con los siguientes datos:\nNombre completo\nTu nombre y apellido.\nOrganización\nEl organismo, licenciataria, cooperativa o empresa a la que representás.\nSos un…\nTu perfil: Gobierno / Regulador, Institución de Financiamiento para el Desarrollo,\nInversor / Fondo de Infraestructura, Empresa Tecnológica, u Otro.\nEmail\nSe usa para iniciar sesión y para las notificaciones de la cuenta.\nContraseña\nMínimo 8 caracteres.\nAl enviar el formulario, la plataforma crea la cuenta y te redirige al panel principal."
  },
  {
    "title": "2.2 Iniciar sesión",
    "text": "En /app/login.html ingresá tu email y contraseña. Si tu cuenta tiene activada la verificación en dos pasos, la plataforma te va a pedir el código de tu aplicación autenticadora antes de dejarte entrar (ver sección 9.2).\ninternational-network-advisors.com\nPágina 2"
  },
  {
    "title": "2.3 ¿Olvidaste tu contraseña?",
    "text": "Desde la pantalla de inicio de sesión, hacé clic en “¿Olvidaste tu contraseña?”. Vas a recibir un email con un enlace para definir una nueva contraseña desde /app/reset-password.html."
  },
  {
    "title": "2.4 Selector de idioma",
    "text": "Toda la plataforma está disponible en español e inglés. El selector EN / ES está siempre visible en el encabezado, en la esquina superior derecha, y el cambio de idioma se aplica de inmediato en toda la página, incluyendo los resultados de análisis ya generados."
  },
  {
    "title": "3. Roles de usuario",
    "text": "La plataforma reconoce tres niveles de acceso. El rol lo asigna un Administrador desde el Panel de\nAdministración (sección 8) — todas las cuentas nuevas empiezan como Usuario estándar.\nUsuario estándar\nCrear, editar y eliminar sus propios Proyectos y Programas. Ve únicamente lo que él mismo cargó en el panel principal.\nAdvisor (Asesor)\nTodo lo anterior, más: ver todos los proyectos de la plataforma (no solo los propios), tomar un proyecto y avanzarlo por las etapas del flujo de trabajo (sección 5.9), armar Hojas de Ruta y roles RACI (sección 6), y cargar la Matriz de\nRiesgos de cualquier proyecto (sección 6.3).\nAdministrador\nTodo lo anterior, más: acceso al Panel de Administración para ver todos los usuarios registrados y cambiarles el rol; puede eliminar cualquier proyecto o programa, no solo los propios."
  },
  {
    "title": "4. Panel principal (Proyectos)",
    "text": "Es la primera pantalla que ves al iniciar sesión (/app/dashboard.html) — muestra todos tus proyectos en una grilla, con un chip de color indicando el estado de cada uno. Si tu cuenta es Advisor o Administrador, vas a ver un aviso indicando que estás viendo todos los proyectos de la plataforma, no solo los tuyos."
  },
  {
    "title": "4.1 Estados de un proyecto",
    "text": "Al crear un proyecto — o al guardar cambios en uno existente — queda en estado No analizado: el análisis con IA ya no se dispara automáticamente, hay que iniciarlo manualmente con la opción Análisis IA del menú\nAnálisis en la ficha del proyecto (ver secciones 5.3 y 5.4). Mientras se está procesando, el proyecto pasa al estado Analizando (o Error si algo falla). Una vez que el análisis termina, el estado que se muestra es directamente la etapa del Investment Readiness Index™ que le corresponde:\n•\nConcept Stage (Etapa de Concepto) — el proyecto recién está tomando forma.\n•\nEarly Structuring (Estructuración Temprana) — hay una propuesta con elementos clave definidos, pero incompleta.\n•\nAdvanced Structuring (Estructuración Avanzada) — el proyecto está mayormente estructurado y listo para negociar con financiadores.\ninternational-network-advisors.com\nPágina 3\n•\nInvestment Ready (Listo para Inversión) — el proyecto cumple los criterios para presentarse formalmente ante financiadores."
  },
  {
    "title": "4.2 Filtros y búsqueda",
    "text": "Encima de la grilla hay filtros combinables: Estado (incluye No analizado), Tipo de proyecto, Programa, rango de fechas (Desde / Hasta), un mínimo de beneficiarios, y un buscador de texto libre. El botón “Limpiar filtros” los resetea todos de una vez."
  },
  {
    "title": "4.3 Descargar PDF desde la grilla",
    "text": "Cada fila tiene también un ícono que descarga el mismo informe en PDF descripto en la sección 5.8, sin necesidad de entrar primero a la ficha del proyecto. Disponible para cualquier proyecto visible en la grilla — propio, o de otro usuario si estás viendo todos los proyectos como Advisor o Administrador."
  },
  {
    "title": "4.4 Eliminar un proyecto",
    "text": "Cada fila tiene un botón de eliminar, disponible para el dueño del proyecto o para un Administrador. La acción pide confirmación antes de borrar el proyecto de forma permanente."
  },
  {
    "title": "5.1 Cargar un proyecto nuevo",
    "text": "Desde el botón “Enviar Nuevo Proyecto” accedés al formulario de carga (/app/new-project.html), con los siguientes campos:\nNombre del proyecto\nUn nombre identificatorio.\nTipo de proyecto\nSistema de Cable Submarino, Backbone de Fibra / Última Milla, Acceso\nInalámbrico Fijo (FWA), Red Mayorista Neutral (5G/FWA), Datacenter para\nCargas de IA, Comunicaciones Satelitales, u Otro.\nPrograma (opcional)\nSi el proyecto forma parte de una iniciativa más amplia, elegís el Programa al que pertenece (o creás uno nuevo sin salir de esta pantalla).\nPaís\nSelector con los 35 países soberanos de América.\nBeneficiarios alcanzados (opcional)\nCantidad de hogares, comercios o establecimientos públicos alcanzados — fortalece el caso para financiamiento del Fondo del Servicio Universal en proyectos de última milla.\nDescripción del proyecto\nEl campo central del análisis: sector, escala, tipo de patrocinador, etapa actual, fuentes de financiamiento consideradas, riesgos clave. Cuanto más detalle, más preciso es el análisis.\nDocumentos de respaldo\nCuatro zonas de carga opcionales: carpeta técnica, documentación económico-financiera, documentación administrativa, y otros adjuntos.\nEl proyecto se guarda en estado No analizado. El análisis con IA no se ejecuta al enviar el formulario — ver sección 5.4 para iniciarlo.\ninternational-network-advisors.com\nPágina 4"
  },
  {
    "title": "5.2 Templates guiados",
    "text": "En lugar de escribir la descripción libremente, muchos tipos de proyecto y Programas ofrecen un botón\n“Completar usando template” que abre un formulario estructurado, campo por campo, basado en los requisitos oficiales de ENACOM. Al terminar, el sistema compila automáticamente todo lo cargado en el campo de descripción — lo que hayas dejado en blanco simplemente no aparece.\nTemplates de tipo de proyecto disponibles:\n•\nDatacenter — basado en el template oficial de ENACOM para propuestas de Datacenter (v3, julio 2026):\ndatacenters tradicionales, edge/PyME, híbridos y de IA.\n•\nCable Submarino — incorpora las recomendaciones del informe 2026 del International Advisory Body on\nSubmarine Cable Resilience.\n•\nRed Mayorista Neutral (5G/FWA) — basado en la Resolución ENACOM 951/2025 y su Anexo I (diseño técnico, zona de despliegue, neutralidad e interconexión).\nSi el Programa elegido tiene su propio template asignado, aparece además un botón “Completar usando el template del programa” — independiente del anterior, podés usar los dos."
  },
  {
    "title": "5.3 Controles de la ficha del proyecto",
    "text": "En la ficha de un proyecto (/app/project.html) los controles están agrupados en dos menús desplegables, con el mismo estilo visual, ubicados en dos lugares a la vez: justo debajo del título del proyecto, y también duplicados en el encabezado superior de la página — así quedan siempre al alcance sin necesidad de volver a hacer scroll hacia arriba.\nProyecto\nNuevo Proyecto (abre el formulario de carga, sección 5.1), Editar, Descargar PDF (sección 5.8), Eliminar y Cerrar (vuelve al panel principal). Editar y Eliminar solo son visibles para el dueño del proyecto o un Administrador.\nAnálisis\nFSU Scoring (sección 5.6, si el proyecto es elegible), Autoevaluación (sección\n5.5) y Análisis IA (sección 5.4). La etiqueta de esta última opción cambia según el estado: “Análisis IA” cuando el proyecto todavía no fue analizado, “Analizando…” mientras se procesa, o “Reintentar Análisis” si el intento anterior falló.\nEn el encabezado superior, junto a estos dos menús aparece también “Ayuda” — por el momento un espacio reservado, todavía sin contenido asociado."
  },
  {
    "title": "5.4 Análisis con IA (manual)",
    "text": "El análisis con IA ya no se ejecuta automáticamente al enviar el formulario. El proyecto queda cargado en estado No analizado y, desde su ficha (/app/project.html), vas a ver la opción Análisis IA en el menú Análisis (sección 5.3). Al hacer clic, la plataforma aplica el Investment Readiness Index™: evalúa el proyecto en 8 dimensiones comunes a todo tipo de infraestructura (claridad legal y regulatoria, madurez del diseño técnico, robustez del modelo financiero, capacidad del patrocinador, evidencia de demanda de mercado, preparación ambiental y social, cobertura de mitigación de riesgos, gobernanza y reportes), más una 9ª dimensión específica según el tipo de proyecto — por ejemplo “Preparación de Espectro y Sitio” para Acceso\nInalámbrico Fijo, o “Preparación de Neutralidad e Interconexión” para Red Mayorista Neutral.\ninternational-network-advisors.com\nPágina 5\nEl proceso suele tardar menos de un minuto; mientras corre, la ficha muestra el estado Analizando con un indicador de progreso. El resultado ubica al proyecto en una de las cuatro etapas descriptas en la sección\n4.1, junto con una lista de próximos pasos prioritarios.\nEste comportamiento manual es consistente entre alta y edición: guardar cambios en un proyecto existente borra el análisis previo y lo deja nuevamente en estado No analizado, listo para que vuelvas a seleccionar\nAnálisis IA cuando quieras generar una versión actualizada (ver sección 5.10). Si el análisis falla o parece haberse quedado colgado, el dueño del proyecto puede reintentarlo con la misma opción del menú (“Reintentar Análisis”) desde la ficha."
  },
  {
    "title": "5.5 Autoevaluación manual",
    "text": "Como alternativa o complemento al análisis automático, desde el menú Análisis de la ficha de un proyecto podés completar una Autoevaluación (/app/assessment.html): un cuestionario de 3 preguntas por dimensión, respondidas en una escala de 1 a 5, que calcula el mismo tipo de puntaje sin depender de la IA. Los resultados de autoevaluación se muestran con una etiqueta que indica que la fuente es manual, no automática."
  },
  {
    "title": "5.6 FSU Scoring",
    "text": "Para proyectos que pueden aplicar al Fondo del Servicio Universal, el menú Análisis de la ficha del proyecto ofrece la opción FSU Scoring (/app/fsu-scoring.html): un puntaje específico de elegibilidad para ese fondo, complementario al Investment Readiness Index™ general."
  },
  {
    "title": "5.7 Multilateral Finance Navigator™",
    "text": "Junto con el puntaje, cada análisis genera recomendaciones concretas de mecanismos de financiamiento entre estos once:\n•\nBancos Multilaterales de Desarrollo\n•\nInstituciones de Financiamiento para el Desarrollo\n•\nProject Finance\n•\nAsociaciones Público-Privadas\n•\nFinanzas Mixtas\n•\nGarantías y Mejora Crediticia\n•\nAgencias de Crédito a la Exportación\n•\nCapital Comercial e Institucional\n•\nFondos de Servicio Universal\n•\nInstrumentos de Deuda en el Mercado de Capitales\n•\nCréditos a Tasa Subsidiada"
  },
  {
    "title": "5.8 Descargar PDF",
    "text": "international-network-advisors.com\nPágina 6\nDesde la opción “Descargar PDF” del menú Proyecto (sección 5.3), visible en la ficha de cualquier proyecto (/app/project.html) tanto para el dueño como para un Advisor que lo esté evaluando, se genera un informe descargable con el mayor detalle posible del proyecto:\n•\nTodos los datos cargados: nombre, tipo, país, beneficiarios, programa, estado, fecha de creación y la descripción completa.\n•\nDocumentos adjuntos, agrupados por categoría (técnica, económico-financiera, administrativa, otros) con el nombre de cada archivo.\n•\nFlujo de trabajo, si el proyecto ya entró al pipeline: etapa actual, asesor asignado y el historial completo de avances.\n•\nFSU Scoring completo, si corresponde: para cada uno de los 7 criterios de la matriz de ENACOM se muestra el dato ingresado (hogares, accesos de fibra, modelo de negocio, tecnología, velocidades, población, antigüedad) junto al puntaje que obtuvo ese criterio, y el puntaje total al final.\n•\nInvestment Readiness Index™ completo, si ya fue analizado: puntaje, etapa, las 8 o 9 dimensiones con su barra de avance, la Hoja de Ruta de Brechas y las recomendaciones del Multilateral Finance\nNavigator™.\n•\nDetalle de la Autoevaluación, cuando el análisis viene del cuestionario manual (sección 5.5): para cada dimensión se listan las 3 afirmaciones del cuestionario junto al puntaje de 1 a 5 que se le asignó a cada una, además del puntaje consolidado de la dimensión.\nLa Matriz de Riesgos y los roles RACI de la Hoja de Ruta (sección 6) todavía no forman parte de este PDF — se consultan directamente en /app/risk-matrix.html y en la ficha de cada Hoja de Ruta.\nEl PDF se genera enteramente en el navegador — no se envía nada a un servidor — y respeta el idioma en el que estés viendo la página en ese momento. Si el proyecto todavía no fue analizado, el PDF lo indica en lugar de mostrar esas secciones."
  },
  {
    "title": "5.9 Flujo de trabajo",
    "text": "El bloque Flujo de Trabajo, visible en la ficha de todo proyecto, muestra siempre el avance a través de las cuatro etapas del Investment Readiness Index™, incluso antes de que el proyecto haya sido analizado. Las acciones de avance son exclusivas de los Advisors: un Advisor puede “tomar” un proyecto y avanzarlo manualmente por esas cuatro etapas, dejando un registro histórico de quién avanzó cada etapa y cuándo, visible en la misma ficha para cualquier usuario que la consulte."
  },
  {
    "title": "5.10 Editar o eliminar un proyecto",
    "text": "El dueño del proyecto (o un Administrador) puede editarlo en cualquier momento desde la opción Editar del menú Proyecto en su ficha (sección 5.3). Al guardar cambios, la plataforma borra el análisis anterior y el proyecto vuelve al estado No analizado — el análisis ya no se recalcula solo. Volvé a seleccionar Análisis IA en el menú Análisis cuando quieras generar un análisis actualizado con los cambios (ver sección 5.4).\nEliminar un proyecto, desde la opción Eliminar del mismo menú, es una acción permanente y pide confirmación.\ninternational-network-advisors.com\nPágina 7"
  },
  {
    "title": "6. Hoja de Ruta: Matriz de Riesgos y Módulo RACI",
    "text": "La ficha de un proyecto puede tener una o más Hojas de Ruta — listas de pasos secuenciales (por ejemplo,\n“Elaboración de Estudio Técnico” o un trámite ante un organismo) que un Advisor o Administrador arma a partir de una plantilla reutilizable y aplica a un proyecto puntual. Desde esta actualización, cada paso incorpora una asignación explícita de roles RACI por entidad, y todo el proyecto cuenta además con una\nMatriz de Riesgos independiente del análisis de riesgo que genera el Análisis IA (sección 5.4)."
  },
  {
    "title": "6.1 ¿Qué es la Hoja de Ruta de un proyecto?",
    "text": "Una Hoja de Ruta es una lista ordenada de pasos con estado propio — pendiente, en curso, completado o bloqueado — que se sigue paso a paso hasta terminar. Un Advisor o Administrador crea primero una plantilla reutilizable (con sus pasos y roles definidos) y luego la aplica a un proyecto concreto, generando una instancia con su propio seguimiento. El dueño del proyecto ve el estado de cada paso de forma directa en la ficha del proyecto (/app/project.html); avanzar los pasos es una acción exclusiva de Advisor o Administrador, igual que con el flujo de trabajo general (sección 5.9)."
  },
  {
    "title": "6.2 Roles RACI por paso",
    "text": "Cada paso de una Hoja de Ruta reemplaza el antiguo campo único de “entidad responsable” por una asignación explícita de roles, siguiendo el modelo RACI — un estándar de gestión de proyectos para dejar sin ambigüedad quién hace qué:\nR\nResponsable — ejecuta la tarea del paso.\nA\nAprobador (Accountable) — autoriza o valida el resultado del paso; lo recomendable es que cada paso tenga un único Aprobador.\nC\nConsultado — aporta información u opinión antes de que el paso avance.\nI\nInformado — se entera del resultado del paso, sin intervenir en su ejecución.\nUn mismo paso puede tener varias entidades, cada una con su propio rol — por ejemplo, la cooperativa que ejecuta un estudio técnico (Responsable) con ENACOM como Aprobador. Los roles se cargan al armar la plantilla de la Hoja de Ruta (solo Advisor o Administrador); en la ficha de seguimiento de cada instancia, todos los usuarios ven distintivos con la letra del rol y el nombre de la entidad junto a cada paso."
  },
  {
    "title": "6.3 Matriz de Riesgos",
    "text": "Cada proyecto tiene su propia Matriz de Riesgos (/app/risk-matrix.html), un registro estructurado y editable de los riesgos identificados, pensado para seguimiento activo durante toda la ejecución del proyecto — a diferencia del párrafo narrativo de riesgo y mitigación que ya incluye el Análisis IA como una de sus 8-9 dimensiones (sección 5.4), que refleja apenas una foto del momento del análisis.\nCada riesgo cargado tiene:\nCategoría\nRegulatorio, técnico, financiero, operativo, ambiental, político, de mercado, de ejecución, u otro.\ninternational-network-advisors.com\nPágina 8\nProbabilidad e impacto\nDos valores de 1 a 5 cada uno.\nScore y severidad\nEl score se calcula automáticamente (probabilidad × impacto, de 1 a 25) y se clasifica en cuatro bandas: bajo (hasta 4), medio (hasta 9), alto (hasta 15) o crítico (más de 15).\nMedidas de mitigación\nTexto libre con las acciones previstas para reducir el riesgo.\nEntidad responsable\nQuién monitorea y mitiga ese riesgo puntual — no necesariamente el dueño del proyecto.\nEstado\nAbierto, en mitigación, mitigado o cerrado.\nSolo un Advisor o Administrador puede cargar, editar o eliminar riesgos, desde /app/risk-matrix.html. El dueño del proyecto ve en su ficha un resumen de solo lectura — cantidad de riesgos por banda de severidad y los más críticos — con un enlace a la matriz completa si tiene permiso para verla.\ninternational-network-advisors.com\nPágina 9"
  },
  {
    "title": "7. Programas",
    "text": "Un Programa agrupa varios proyectos relacionados bajo una misma iniciativa u organización — por ejemplo, un plan provincial de conectividad que combine un cable submarino, un backbone de fibra y despliegues de última milla como proyectos independientes, cada uno con su propio financiamiento y análisis."
  },
  {
    "title": "7.1 Crear un Programa",
    "text": "Desde /app/programs.html → “Nuevo Programa” (/app/new-program.html), completá:\nNombre del programa\nUn nombre identificatorio.\nOrganización presentante\nQuién impulsa el programa.\nTipo de organización\nNaturaleza jurídica de la organización presentante.\nTipo(s) de proyecto que abarca\nSelección múltiple — un Programa puede cubrir varios tipos de infraestructura a la vez, a diferencia de un proyecto individual.\nTemplate de programa (opcional)\nSi el programa corresponde a una línea estandarizada de ENACOM, elegís su template (ver 7.2) para que quien presente un proyecto bajo este programa tenga un formulario guiado.\nDescripción (opcional)\nTexto libre describiendo el programa.\nDocumentos de respaldo (opcional)\nPDFs, imágenes u otros archivos: memos técnicos, mapas, fotos, presentaciones."
  },
  {
    "title": "7.2 Templates de Programa disponibles",
    "text": "Estos seis templates cubren líneas y programas oficiales de ENACOM. A diferencia de los templates de tipo de proyecto (sección 5.2), estos se asignan al Programa — cualquiera que presente un proyecto bajo ese\nPrograma recibe automáticamente el botón para completarlo con el formulario guiado correspondiente.\nTemplate\nResolución\nQué cubre\nFinanciamiento por\nMercado de Capitales\nRes.\nENACOM\n1191/25\nEl FSU coinvierte en Obligaciones Negociables emitidas por licenciatarias TIC para financiar última milla, interconexión mayorista, cobertura o IA aplicada a TIC.\nRed Mayorista Neutral (Programa)\nRes.\nENACOM\n951/25\nPostulación al Programa en sí — alineación con los 4 criterios de evaluación del Anexo, presupuesto y cofinanciamiento.\nComplementa (no reemplaza) el template técnico de tipo de proyecto “Red Mayorista Neutral”.\nCréditos a Tasa\nSubsidiada (TASU)\nRes.\nENACOM\n1385/25\nEl FSU subsidia hasta 15 puntos de la tasa de interés de créditos otorgados por entidades autorizadas por el BCRA a licenciatarios TIC.\ninternational-network-advisors.com\nPágina 10\nFATIC — General /\nProvisión de\nEquipamiento\nRes.\nENACOM\n950/25\nEl Programa base “Financiamiento y Apoyo a Proveedores de\nServicios de TIC”: elegibilidad general y la línea de Provisión de\nEquipamiento Tecnológico.\nAsistencia ante\nEmergencias y\nCatástrofes\nRes.\nENACOM\n449/21 (act.\n323/25)\nAporte No Reembolsable de hasta el 100% de la inversión financiable (tope $150.000.000 por proyecto) para reponer infraestructura TIC dañada por una emergencia o catástrofe declarada.\nConectividad de Interés\nPúblico (C.I.P.)\nRes.\nENACOM\n1072/24\nPara organismos de gobierno que necesiten conectividad, pisos tecnológicos o equipamiento como insumo de un plan sectorial de educación, salud o seguridad."
  },
  {
    "title": "7.3 Editar o eliminar un Programa",
    "text": "El dueño del programa (o un Administrador) puede editarlo o eliminarlo desde /app/programs.html, igual que con los proyectos."
  },
  {
    "title": "8. Panel de Administración",
    "text": "Visible solo para cuentas con rol Administrador, en /app/admin.html. Muestra todos los usuarios registrados en la plataforma, con un filtro por rol, y permite cambiarle el rol a cualquier usuario (Usuario estándar, Advisor o Administrador). Por seguridad, ningún usuario puede cambiar su propio rol — el cambio siempre lo hace otro Administrador."
  },
  {
    "title": "9. Perfil y seguridad",
    "text": "Desde el avatar en el encabezado accedés a tu perfil (/app/profile.html)."
  },
  {
    "title": "9.1 Datos personales",
    "text": "Podés actualizar tu nombre completo y organización en cualquier momento."
  },
  {
    "title": "9.2 Verificación en dos pasos (MFA)",
    "text": "Desde la misma pantalla podés activar la verificación en dos pasos con una aplicación autenticadora (TOTP)\n— escaneás un código QR y confirmás con el primer código generado. Una vez activada, cada inicio de sesión te va a pedir ese código adicional después de la contraseña."
  },
  {
    "title": "10. Preguntas frecuentes",
    "text": "¿Puedo dejar campos en blanco al usar un template?\nSí. Todo lo que dejes sin completar simplemente no aparece en la descripción generada — no es obligatorio llenar el formulario entero para guardar un borrador.\n¿Cuándo se ejecuta el análisis con IA de un proyecto nuevo?\ninternational-network-advisors.com\nPágina 11\nNunca automáticamente. Después de enviar el formulario, el proyecto queda en estado No analizado; entrá a su ficha y seleccioná Análisis IA en el menú Análisis (sección 5.3) cuando quieras generarlo.\n¿El análisis se vuelve a correr si edito el proyecto?\nNo, ya no en forma automática. Guardar cambios borra el análisis anterior y deja el proyecto en estado No analizado; volvé a seleccionar Análisis IA en el menú Análisis de la ficha del proyecto cuando quieras generar el nuevo análisis.\n¿Por qué el análisis ya no se ejecuta automáticamente?\nPara darte control sobre el momento en que se corre — por ejemplo, para terminar de cargar toda la documentación de respaldo antes de generar el análisis, en lugar de consumirlo de forma prematura con datos incompletos. El comportamiento es el mismo tanto para proyectos nuevos como editados.\n¿Puedo usar el template de tipo de proyecto y el del Programa a la vez?\nSí — son independientes y complementarios; cada uno agrega su propio contenido a la descripción.\n¿Puedo descargar un PDF de mi proyecto?\nSí, con la opción “Descargar PDF” del menú Proyecto en la ficha del proyecto (sección 5.8), o con el ícono de la misma fila en el panel principal sin entrar a la ficha (sección 4.3). Incluye los datos del proyecto y, si ya fue analizado, el resultado completo del Investment Readiness Index™ y las recomendaciones del Multilateral\nFinance Navigator™. Está disponible tanto para el dueño del proyecto como para un Advisor que lo esté evaluando.\n¿Quién puede cargar la Matriz de Riesgos o definir los roles RACI de una Hoja de Ruta?\nSolo un Advisor o Administrador. El dueño del proyecto ve ambas cosas en modo lectura: el resumen de riesgos por severidad en su ficha, y los distintivos RACI de cada paso en el seguimiento de la Hoja de Ruta (sección 6).\n¿La Matriz de Riesgos reemplaza al riesgo que menciona el Análisis IA?\nNo. El Análisis IA (sección 5.4) incluye un párrafo de riesgo y mitigación como una de sus dimensiones, una foto del momento del análisis. La Matriz de Riesgos (sección 6.3) es un registro aparte, estructurado y editable, para el seguimiento activo de riesgos durante toda la ejecución del proyecto.\n¿Quién puede ver mis proyectos?\nPor defecto, solo vos. Los usuarios con rol Advisor o Administrador ven todos los proyectos de la plataforma para poder evaluarlos.\n¿Cómo cambio de Usuario estándar a Advisor?\nEse cambio lo hace un Administrador desde el Panel de Administración (sección 8); no podés auto-asignarte un rol distinto.\n¿Dudas adicionales? Escribinos desde el formulario de contacto en international-network-advisors.com/contact.html.\ninternational-network-advisors.com\nPágina 12"
  }
];
