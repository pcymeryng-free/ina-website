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
├── platform.html        → Roadmap de evolución de la plataforma (5 etapas)
├── contact.html         → Formulario de solicitud de advisory
├── assets/
│   ├── style.css        → Tokens de diseño y todos los componentes visuales
│   └── script.js         → Menú móvil, scroll reveal, TOC scrollspy, formulario
└── README.md             → Este archivo
```

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
  (Etapas 3–5) — todavía no implementados.
- Home rediseñado (jul. 2026) para alinearse al mockup del proyecto: hero con dos CTAs,
  4 tarjetas de audiencia (Governments / Multilateral Organizations / Investors & Funds /
  Operators & Technology Leaders), tira de industrias, proceso de 7 pasos de "The INA Project
  Structuring Framework™", Featured Cases + Latest Insights, banner de CTA final y tira de
  "Trusted by". Nav actualizado: About · Framework · Services · Industries · Multilateral
  Finance · Knowledge Center · Insights · INA Platform (Coming Soon) · Contact Us.
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
# ina-website
