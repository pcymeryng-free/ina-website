# INA — International Network Advisors
### Sitio web institucional

Sitio estático (HTML + CSS + JS puro, sin frameworks ni build) generado a partir del documento
`INA_Digital_Platform_.pdf` del proyecto.

## Estructura

```
ina-website/
├── index.html         → Home
├── why-ina.html        → Misión, visión, posicionamiento estratégico
├── framework.html       → Flagship: INA Frameworks™ Suite (F1–F6) + Multilateral Finance
├── services.html        → Los 8 servicios, en detalle
├── industries.html      → Los 10 sectores de infraestructura digital
├── knowledge.html       → Knowledge Center (white papers, guías, templates)
├── insights.html         → Insights (comentario y análisis de mercado, actualizado)
├── platform.html        → Roadmap de evolución de la plataforma (5 etapas)
├── contact.html         → Formulario de solicitud de advisory
├── assets/
│   ├── style.css        → Tokens de diseño y todos los componentes visuales
│   ├── script.js         → Menú móvil, scroll reveal, TOC scrollspy, formulario
│   └── i18n.js            → Selector de idioma EN/ES (diccionario + lógica de toggle)
└── README.md             → Este archivo
```

## Selector de idioma (EN / ES)

El sitio es bilingüe. Arriba a la derecha del menú (y dentro del menú móvil) hay un
toggle **EN / ES**. Al hacer clic:

- Todo el texto de la página cambia instantáneamente (sin recargar), usando un diccionario
  de ~525 claves generado en `assets/i18n.js`.
- La preferencia de idioma se guarda en `localStorage`, así que la próxima visita recuerda
  el idioma elegido.
- El atributo `lang` del `<html>` se actualiza acorde (bueno para accesibilidad y SEO).

Si en el futuro agregás contenido nuevo, hacelo en `build_site.py` (no directamente en los
`.html`): ese script es la única fuente de verdad — genera tanto el HTML con el texto en
inglés visible por defecto como el diccionario de `i18n.js`, así nunca quedan desincronizados.

⚠️ **Importante:** no muevas `index.html` (ni ningún otro `.html`) fuera de esta carpeta sin
llevarte también `assets/`. Los links entre páginas y las hojas de estilo usan rutas relativas.

## Cómo verlo

### Opción rápida — sin instalar nada
Doble clic en `index.html`. Se abre en tu navegador y navegás con los links normalmente.

### Opción recomendada — con servidor local
Evita bloqueos del navegador con `file://` y es más parecido a cómo se va a ver online.

**Con Python** (Mac/Linux lo trae instalado; Windows: [python.org](https://www.python.org/downloads/)):
```bash
cd ina-website
python3 -m http.server 8000
```
Abrís `http://localhost:8000` en el navegador.

**Con Node:**
```bash
cd ina-website
npx serve
```

**Con VS Code:** extensión "Live Server" → clic derecho sobre `index.html` → *Open with Live Server*.

## Cómo publicarlo online

- **Netlify Drop**: arrastrás la carpeta completa a [app.netlify.com/drop](https://app.netlify.com/drop) → URL pública en segundos.
- **Vercel**: `vercel deploy` desde la carpeta (requiere cuenta).
- **GitHub Pages**: subís la carpeta a un repo de GitHub y activás Pages en la configuración del repo (rama `main`, carpeta `/`).

## Estado actual / próximos pasos

- El formulario de `contact.html` es funcional en el cliente (muestra confirmación) pero
  **no está conectado a ningún backend real** — falta integrar email/CRM.
- Los botones de descarga en `knowledge.html` y el "Company Profile (PDF)" son placeholders
  ("Coming soon") — faltan los documentos reales para linkear.
- La sección *Platform* describe el roadmap hacia agentes de IA y dashboards interactivos
  (Etapas 3–5) — todavía no implementados, tal como lo marca el blueprint.
- Diseño: tema "chart náutico" (tinta marina + papel gris-azulado + acento ámbar), tipografías
  Fraunces / IBM Plex Sans / IBM Plex Mono cargadas desde Google Fonts vía CDN.

## Paleta y tipografía (referencia rápida)

| Token | Valor | Uso |
|---|---|---|
| `--ink` | `#0B1526` | Fondo secciones oscuras (hero, frameworks) |
| `--paper` | `#E7EBE7` | Fondo secciones claras |
| `--amber` | `#D9922E` | Acento único (CTAs, highlights) |
| `--serif` | Fraunces | Titulares |
| `--sans` | IBM Plex Sans | Cuerpo de texto |
| `--mono` | IBM Plex Mono | Eyebrows, datos, etiquetas |
