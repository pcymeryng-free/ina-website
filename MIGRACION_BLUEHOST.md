# Migración de INA Platform a Bluehost (producción) + Vercel (desarrollo)

Dominio confirmado: **international-network-advisors.com**. El código ya está listo (Parte 4 hecha); lo que queda es terminar el DNS (Parte 3, en curso) y los pasos manuales de Bluehost/Supabase (Partes 1, 2 y 5).

## Qué se mueve y qué no

| Componente | Hoy | Después de migrar |
|---|---|---|
| Sitio institucional + plataforma (HTML/CSS/JS) | Vercel | **Bluehost** (producción) — Vercel sigue sirviendo lo mismo como entorno de pruebas |
| Base de datos, login, storage (Supabase) | Supabase | **Sin cambios** — es un servicio aparte, no depende de dónde esté el frontend |
| Función de análisis con IA (`api/analyze-project.js`) | Vercel (serverless) | **Se queda en Vercel** — tu plan de Bluehost no tiene Node.js, así que esta pieza no se puede mover sin reescribirla en otro lenguaje. El sitio en Bluehost la va a llamar por HTTPS a través de un subdominio |

Confirmaste que en cPanel no aparece el ícono "Setup Node.js App", así que este plan asume esa función se queda en Vercel de forma permanente, no solo como paso intermedio.

## Antes de empezar, vas a necesitar

- El dominio exacto registrado en Bluehost.
- Acceso a cPanel (File Manager o FTP) de Bluehost.
- Acceso al proyecto en Vercel (para agregar el subdominio `api`).
- Acceso al proyecto en Supabase (Dashboard).
- Que yo pueda editar 2 archivos del código (`api/analyze-project.js` y `assets/platform.js`) antes de que subas nada — están en la Parte 4.

---

## Parte 1 — Subir el sitio estático a Bluehost

⚠️ `international-network-advisors.com` está configurado como **addon domain** en tu cuenta de Bluehost (no como dominio principal), así que su carpeta real **no es `public_html` a secas** — es:

```
public_html/website_e3ff840a
```

(confirmado en cPanel → Domains → columna Document Root para `international-network-advisors.com`). Todo lo de abajo va **dentro de esa carpeta**, no en el `public_html` de nivel superior (ese le pertenece al dominio principal de la cuenta).

⚠️ Dentro de `website_e3ff840a` hoy vive una instalación de **WordPress** (carpetas `wp-content`, `wp-admin`, `wp-includes`, archivo `wp-config.php`, etc.) — el sitio viejo de INA se servía desde `wp-content/themes/Archivo`. Decidiste reemplazar todo eso: el sitio nuevo es estático y no necesita WordPress, así que va directo en la raíz de `website_e3ff840a`, no dentro de esa subcarpeta.

1. **Backup primero** (por si querés recuperar algo del sitio viejo más adelante): en File Manager, seleccioná todo el contenido de `website_e3ff840a` → botón **Compress** → descargá el .zip a tu computadora. Si el sitio viejo usaba una base de datos de WordPress, también podés exportarla desde **phpMyAdmin** (cPanel → Databases) antes de seguir — no es obligatorio para lo que sigue, pero es tu única chance fácil de guardarla.
2. Una vez que tengas el backup, **borrá todo el contenido** de `website_e3ff840a` (todos los archivos y carpetas de WordPress) — tiene que quedar vacía.
3. En cPanel, abrí **File Manager** (o conectate por FTP con un cliente como FileZilla, usando las credenciales que te dio Bluehost).
4. Navegá a `public_html/website_e3ff840a` (ahora vacía).
5. Subí **todo** el contenido de tu carpeta del proyecto **excepto la carpeta `api/`** — esa función no corre en Bluehost, no tiene sentido subirla (y evita exponer innecesariamente ese código).
6. Verificá que la estructura dentro de `website_e3ff840a` quede igual a la que tenés ahora: `index.html`, `app/`, `assets/`, `supabase/` (esta última podés omitirla también, son solo scripts SQL de referencia, no se ejecutan desde el sitio), etc.
7. Los archivos ya usan rutas absolutas (`/assets/style.css`, `/assets/i18n.js`) — mientras la estructura de carpetas se mantenga igual dentro de `website_e3ff840a`, no hay que tocar ningún link interno.

La base de datos de WordPress (si existía una) queda huérfana pero inofensiva — no hace falta borrarla ahora; si en algún momento querés limpiarla del todo, se hace desde cPanel → MySQL Databases.

## Parte 2 — Reemplazar `vercel.json` por `.htaccess` ✅ hecho

Vercel usa `vercel.json` para las redirecciones de URLs viejas; Bluehost (Apache) usa un archivo `.htaccess`. Ya está generado y guardado como `.htaccess` en la raíz de tu carpeta del proyecto — subilo a `public_html/website_e3ff840a` (junto a `index.html`) cuando hagas la Parte 1, no al `public_html` de nivel superior. Reproduce las mismas 7 reglas que tenés hoy en `vercel.json`, más un par de líneas opcionales de endurecimiento (bloquear listado de directorios).

## Parte 3 — Subdominio `api.international-network-advisors.com` apuntando a Vercel — en curso

Esto es lo que permite que el sitio en Bluehost siga usando la función de IA que corre en Vercel, con una URL prolija en vez del link crudo de `.vercel.app`.

1. En **Vercel** → tu proyecto → **Settings → Domains** → agregá `api.international-network-advisors.com`. (Hecho — mostró "Invalid Configuration", es normal en este punto.)
2. Vercel te va a mostrar un registro **CNAME** para agregar (normalmente algo como `cname.vercel-dns.com`).
3. En **Bluehost** → cPanel → **Zone Editor** → en la zona de `international-network-advisors.com`, agregá:
   - Tipo: `CNAME`
   - Nombre/host: `api`
   - Apunta a: el valor exacto que te dio Vercel en el paso 2
4. Esperá la propagación (de minutos a un par de horas para un CNAME nuevo). Lo podés chequear visitando `https://api.international-network-advisors.com` — debería responder algo de Vercel (aunque sea un 404, ya confirma que el DNS está resolviendo ahí), o pedime que lo verifique yo.

## Parte 4 — Cambios de código ✅ hecho

Ya editados y verificados, con el dominio real:

**`api/analyze-project.js`** — agregadas cabeceras CORS restringidas a `https://international-network-advisors.com`, `https://www.international-network-advisors.com` y cualquier `*.vercel.app` (para que el entorno de pruebas en Vercel siga funcionando). No abierto a cualquier origen (`*`), porque este endpoint usa el token de sesión del usuario. Maneja también el preflight `OPTIONS` que el navegador manda antes del POST real.

**`assets/platform.js`** — `requestAnalysis()` ahora usa `analyzeProjectUrl()`: si el sitio corre en `international-network-advisors.com` (o `www.`), llama a `https://api.international-network-advisors.com/analyze-project`; en cualquier otro caso (Vercel, localhost) sigue usando la ruta relativa `/api/analyze-project` como antes. El mismo código funciona sin cambios en ambos entornos.

## Parte 5 — Actualizar Supabase

En **Supabase → Authentication → URL Configuration**:
- **Site URL**: `https://international-network-advisors.com` (reemplaza la URL de Vercel que tenías antes).
- **Redirect URLs**: agregá `https://international-network-advisors.com/app/reset-password.html` (y de paso, dejá también la URL de Vercel que uses para pruebas, así el flujo de "olvidé mi contraseña" funciona en ambos entornos).

Esto también resuelve de raíz el problema que tuvimos con el link de reset de contraseña — un dominio propio y estable no tiene el problema de las URLs de preview que cambian en cada deploy.

## Parte 6 — Checklist antes de cortar a producción

- [ ] `https://international-network-advisors.com` carga el sitio institucional correctamente.
- [ ] `https://international-network-advisors.com/app/login.html` carga y el login funciona (prueba con una cuenta real).
- [ ] Los links viejos (`https://international-network-advisors.com/dashboard.html`, etc.) redirigen bien a `/app/...` (probá el `.htaccess`).
- [ ] Crear un proyecto nuevo y correr el análisis de IA — confirma que el CORS y el subdominio `api.` están bien configurados.
- [ ] "Olvidé mi contraseña" manda el mail y el link vuelve a `international-network-advisors.com` (no a Vercel).
- [ ] Los toggles de idioma EN/ES funcionan en todas las páginas.

## Parte 7 — Formulario de contacto: que mande el email de verdad ✅ hecho

**Historia corta:** probamos primero con una función en Vercel (`api/contact.js`) que mandaba el mail por SMTP hacia tu casilla de Bluehost. Funcionaba, pero dependía de 4 variables de entorno en Vercel (con varios problemas para cargarlas bien) y de un salto entre dos servidores distintos (Vercel → Bluehost) que traía dolores de cabeza de entrega. Decidiste no depender de Vercel para esto, con razón — así que el enfoque final es mucho más simple:

**`contact.php`**, un archivo PHP que corre **directamente en Bluehost**, en la raíz del sitio (al lado de `contact.html`, `index.html`, etc. — **no** dentro de la carpeta `api/`, esa sigue siendo solo para `analyze-project.js` en Vercel). Usa la función `mail()` que trae PHP de fábrica, la cual entrega el mensaje directo al mismo servidor de correo (Exim) que ya maneja `info@inaai.co` — sin credenciales, sin variables de entorno, sin llamada entre servidores distintos. Es exactamente el mecanismo que usan la enorme mayoría de los formularios de contacto de WordPress en hosting compartido como el tuyo.

Ventaja extra: como `contact.php` vive en el mismo dominio que el sitio, el `fetch()` del formulario es *same-origin* — no hace falta configurar CORS ni el subdominio `api.` para esto (esos siguen existiendo solo para el análisis de IA, que sí necesita Node.js).

**Qué subir a Bluehost** (`public_html/website_e3ff840a`):
- `contact.php` (nuevo — este si tiene que subirse, a diferencia de todo lo que vive en `api/`)
- `contact.html`, `assets/script.js`, `assets/i18n.js` (actualizados — ya no llaman a Vercel para esto)

**Ya no hace falta:**
- Ninguna variable de entorno en Vercel para el contacto (`SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASS` — se pueden borrar de Vercel si las habías cargado).
- `api/contact.js` ni `package.json` — los borré del proyecto porque ya no se usan.

Si `mail()` fallara por algún motivo del lado del servidor, el formulario no se rompe silenciosamente: cae automáticamente a la vieja solución de `mailto:` como respaldo, así el visitante igual puede escribirte.

⚠️ **Nota sobre caché en Bluehost:** en esta migración nos encontramos con que Bluehost cachea archivos estáticos (`.js`) del lado del servidor — subir un archivo nuevo con el mismo nombre no siempre alcanza para que los visitantes vean la versión nueva. Por eso `contact.html` pide `assets/script.js?v=3` en vez de la ruta pelada — cada vez que edite `script.js` o `i18n.js` de forma significativa, voy a subir el número de versión (`?v=4`, `?v=5`, etc.) en todas las páginas para forzar que se traigan la versión nueva, sin depender de que canches el caché vos mismo.

## Parte 8 — Log de actividad (visitas al sitio + acciones en la plataforma)

Igual que Parte 7 (contacto), esto necesita PHP corriendo directamente en Bluehost — no hay Node ahí. Dos archivos nuevos, **en la raíz del sitio** (al lado de `contact.php`, `index.html`, etc.):

- **`log-visit.php`** — registra cada visita anónima al sitio institucional (IP, país vía el header que agrega Cloudflare, user-agent, página vista) en la tabla `activity_log` de Supabase. Lo llama `assets/script.js` con un beacon `<img>` (no `fetch()`/POST — el "Human Presence Check" de Bluehost bloquea justo ese patrón, el mismo problema que tuvimos con el formulario de contacto). No tiene secretos adentro: usa la Anon Key de Supabase (pública) más una política RLS que solo deja insertar filas anónimas de tipo "vista de página".
- **`whoami.php`** — devuelve IP/país en JSON, usado por `assets/platform.js` (páginas de `app/`) para agregarle esos mismos datos a las filas que ya inserta directo con el usuario logueado. Tampoco tiene secretos.

**Antes de subir el código**, corré `supabase/migration_v63_activity_log.sql` en el SQL Editor de Supabase (crea la tabla `activity_log` y sus políticas RLS) — si el código llega a Bluehost antes que la tabla exista en Supabase, el log simplemente no escribe nada (falla silenciosamente), no rompe el sitio.

**Qué subir a Bluehost:**
- `log-visit.php`, `whoami.php` (nuevos)
- `assets/script.js`, `assets/platform.js`, `assets/i18n.js` (actualizados)
- `app/activity-log.html` (nuevo — la pantalla donde se ve el log, solo para Admin)
- El resto de `app/*.html` (bump de versión de `i18n.js`/`platform.js` en el `<script>`, y el ítem de menú "Activity Log" en el dropdown de Admin)

⚠️ **Privacidad:** esto registra IP y país de cada visitante del sitio público, aunque no esté logueado — no hay forma de saber quién es una persona anónima más allá de eso. Si el sitio recibe visitas de organismos como Cancillería o del exterior, convendría tener una política de privacidad publicada que lo mencione (Ley 25.326).

---

## Parte 9 — Auditoría de seguridad: XSS en pantallas admin + hardening ✅ hecho

Encontrado en una revisión de seguridad (2026-09-23): las tablas de Contactos/Empresas/Organismos en `app/master-data.html` y la lista de `app/activity-log.html` insertaban datos directo en `innerHTML` sin escapar. Un usuario cualquiera con permiso de cargar contactos (o, para el caso de Activity Log, **cualquier visitante anónimo** vía `log-visit.php`, sin cuenta) podía poner HTML/JS en un nombre/email/empresa y que se ejecutara en el navegador del Admin que abre esa pantalla — como el token de sesión de Supabase vive en `localStorage`, esto es robo de sesión de Admin.

Arreglado en tres capas:
1. **Escapado en el render** — `escapeHtml()` (ya existía en el código pero no se aplicaba en estas tablas) ahora envuelve todo dato de usuario en las 4 tablas de Master Data y en Activity Log. También se agregó `safeUrl()` para el campo "website" de Empresas (evita `javascript:...` como link).
2. **Validación en el origen** — `log-visit.php` ahora rechaza `path` que no sea una ruta relativa (`/algo`) y quita `< > " '` de `path`/`ref` antes de guardarlos.
3. **Content-Security-Policy** — nuevo header en `.htaccess` (`script-src-attr 'none'`, mismo patrón que usa Cloudflare en su propia página de challenge) que bloquea la ejecución de atributos tipo `onerror=`/`onload=` inyectados vía HTML, como defensa adicional por si se escapa algún caso no cubierto por el punto 1.

**Qué subir a Bluehost:**
- `.htaccess` (nuevo header de seguridad)
- `log-visit.php` (validación del parámetro `path`)
- `app/master-data.html`, `app/activity-log.html`

⚠️ **Después de subir**, probar en el navegador: abrir Master Data (las 4 tabs) y Activity Log, y confirmar que cargan bien. Si algo del sitio deja de funcionar por el CSP nuevo (revisar la consola del navegador por errores "Refused to..."), avisar — el header se puede ajustar o sacar sin tocar el resto.

---

## Parte 10 — PWA: instalar la Plataforma como app en el iPhone ✅ hecho

Convierte la plataforma (no el sitio institucional) en una Progressive Web App: agregándola a la pantalla de inicio desde Safari en el iPhone, abre a pantalla completa con ícono propio, sin la barra de Safari — no es una app de la App Store (eso es un proyecto aparte, con cuenta de Apple Developer y revisión de Apple), pero se instala en minutos y reusa toda la plataforma tal como está.

**Archivos nuevos:**
- `manifest.webmanifest` (raíz del sitio) — nombre, ícono, colores, y que abra en `/app/dashboard.html`.
- `assets/images/pwa/icon-*.png` (16/32/180/192/512px) — generados a partir del isotipo de INA que ya usa el header (triángulo + 3 puntos ámbar).

**Cómo instalarla (para explicarle al usuario):**
1. Abrir `https://www.international-network-advisors.com/app/login.html` en Safari en el iPhone (o directo `/app/dashboard.html` si ya está logueado).
2. Tocar el botón "Compartir" (el cuadrado con flecha hacia arriba).
3. "Agregar a pantalla de inicio".
4. Confirmar — queda el ícono de INA en la pantalla de inicio, y al abrirlo entra directo a la plataforma a pantalla completa.

**Qué subir a Bluehost:**
- `manifest.webmanifest`, `assets/images/pwa/` (carpeta completa, nueva)
- `.htaccess` (agrega el tipo MIME de `.webmanifest`)
- Las 31 páginas de `app/*.html` (agregan las etiquetas `<link rel="manifest">`/`apple-touch-icon`/meta tags en el `<head>`)

No incluye Service Worker (caché offline) en esta primera versión — se evaluó y se decidió no sumarlo todavía dado lo mucho que costó destrabar los problemas de caché de Bluehost en la Parte 9/10 de esta sesión; sumaría una capa más de caché para diagnosticar si algo no actualiza. Si en el futuro hace falta que funcione sin conexión, se puede agregar después.

---

## Parte 11 — Descubrimiento: Bluehost también pasa por Cloudflare (caché de borde)

Encontrado el 2026-09-24, debuggeando por qué el fix de CSP (`img-src ... blob:`, ver Parte 9) no aparecía después de subir `.htaccess` dos veces: el sitio devuelve headers `server: cloudflare` / `cf-cache-status` aunque **la cuenta no tiene Cloudflare propio** — Bluehost integra Cloudflare automáticamente para todas sus cuentas de hosting compartido, sin que haga falta (ni sea posible) loguearse a un dashboard de Cloudflare separado.

Cloudflare cachea las respuestas de archivos estáticos (`.css`/`.js`) **en su borde**, headers incluidos — no solo el contenido. Cuando cambia algo que solo afecta los *headers* (como el `.htaccess`, que no toca el contenido de `app.css` en sí), la URL versionada (`app.css?v=N`) puede seguir teniendo cacheada la respuesta vieja con los headers viejos, aunque el archivo en el servidor ya esté actualizado — confirmado con `curl -I` viendo `cf-cache-status: HIT` y el CSP viejo en `app.css?v=17`, mientras que agregarle un parámetro random (`?cachebust=...`) sí traía la versión nueva (`cf-cache-status: MISS`).

**Cómo se resuelve, sin acceso a Cloudflare:** bumpear el número de versión (`?v=N`) de igual manera que para cualquier otro cambio de caché de Bluehost — eso fuerza una URL que Cloudflare nunca vio, así que no tiene nada cacheado para esa clave y pide todo de cero al origin. **Regla nueva a partir de ahora:** cualquier cambio a `.htaccess` (headers, no contenido de archivo) también requiere bumpear el `?v=` de al menos un asset compartido (`app.css` o `platform.js`) para que el navegador vuelva a pedirlo con una URL nueva — aunque el archivo `.css`/`.js` en sí no haya cambiado.

**Actualización 2026-09-24 — también cachea las páginas HTML, no solo `assets/`.** Confirmado con un caso real: se arregló un bug de la cámara (escaneo de tarjetas en Master Data — ver más abajo) subiendo `app/master-data.html` dos veces, y la página seguía mostrando el comportamiento viejo con el ícono de "imagen rota" clásico — imposible con el código nuevo, que ya ni tiene un `<img>`. Entrando a `app/master-data.html?x=2` (cualquier query string nuevo) sí mostró el fix. O sea: las páginas HTML también quedan cacheadas en el borde de Cloudflare, con URL fija (sin `?v=`), así que no hay una forma automática de "bustear" el caché como con los assets.

Se evaluó agregar `Cache-Control` corto a las respuestas HTML vía `.htaccess`, pero ya hay antecedente de que esto rompió algo antes (ver la nota al principio del archivo: un `Cache-Control: no-cache` blanket para `.html` en su momento destapó un bug de auto-redirección infinita en `login.html`, porque dejó de cachearse la respuesta 301 también). Se decidió no tocarlo en ese momento — pero ver la Parte 12 más abajo, donde sí se resolvió.

---

## Parte 12 — Solución definitiva al caché de páginas HTML ✅ hecho (2026-09-25)

Retomado después de que el problema de caché de Cloudflare (Parte 11) causara varios falsos "sigue sin andar" durante la sesión — la mayoría no eran bugs de código sino Cloudflare sirviendo una copia vieja de la página HTML.

Antes de tocar nada, se verificó que `app/login.html` carga bien hoy (sin loop de redirección) — el bug histórico que motivó sacar el `Cache-Control` la primera vez no está reproduciéndose actualmente.

Se agregó, en `.htaccess`:
```apache
<IfModule mod_headers.c>
  <FilesMatch "\.html$">
    Header always set Cache-Control "max-age=60, must-revalidate"
  </FilesMatch>
</IfModule>
```

A propósito **`max-age=60`, no `no-cache`** — distinto de lo que se probó la vez pasada. Con `no-cache` puro, cada rebote de un eventual loop de redirección le pega al servidor de nuevo (eso fue lo que lo hizo visible e infinito la vez pasada). Con 60 segundos de caché, el navegador (y Cloudflare) absorben varios pedidos repetidos a la misma URL dentro de esa ventana — incluyendo, si volviera a pasar, los rebotes de un loop — sin llegar a tumbar nada, pero sin quedar pegado a una versión vieja por horas como pasaba antes.

**Qué esto soluciona:** de acá en adelante, cualquier cambio a una página HTML llega a los usuarios reales (y a las propias pruebas) dentro de 1 minuto como máximo, sin necesitar el truco de `?x=N`. Ya no hace falta seguir usándolo, aunque sigue funcionando como respaldo si hiciera falta forzar una vista fresca al toque.

**Después de subir**, probar especialmente el login (`app/login.html`) varias veces seguidas para confirmar que no reaparece ningún loop, antes de dar esto por cerrado del todo.

---

## Qué queda igual en Vercel

Vercel sigue recibiendo cada push a GitHub y desplegando automáticamente — es tu entorno de pruebas, tal como querés. La única diferencia es que el dominio "real" que le das a usuarios de ENACOM es el de Bluehost, no el de Vercel.

---

**Próximo paso:** terminar la Parte 3 (agregar el registro CNAME en Bluehost) y avisarme cuando esté — reviso que resuelva bien y seguimos con la Parte 1 (subir el sitio) y la Parte 5 (Supabase). Para la Parte 7 (formulario de contacto), cargá las 4 variables SMTP en Vercel cuando tengas la contraseña de `info@inaai.co` a mano.
