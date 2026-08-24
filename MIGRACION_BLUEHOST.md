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

---

## Qué queda igual en Vercel

Vercel sigue recibiendo cada push a GitHub y desplegando automáticamente — es tu entorno de pruebas, tal como querés. La única diferencia es que el dominio "real" que le das a usuarios de ENACOM es el de Bluehost, no el de Vercel.

---

**Próximo paso:** terminar la Parte 3 (agregar el registro CNAME en Bluehost) y avisarme cuando esté — reviso que resuelva bien y seguimos con la Parte 1 (subir el sitio) y la Parte 5 (Supabase). Para la Parte 7 (formulario de contacto), cargá las 4 variables SMTP en Vercel cuando tengas la contraseña de `info@inaai.co` a mano.
