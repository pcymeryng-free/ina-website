/* ---------- Project data review from documents ----------
   Pablo (oct 2026): "cuando se adjuntan nuevos documentos a un proyecto ya
   cargado dar la posibilidad de detectar atributos de los documentos que
   se puedan cargar como atributos del proyecto en INA."

   One modal shared by:
     - app/project.html — "Subir versión actualizada", "Adjuntar documento"
       and "Detectar datos" on an already-attached document (approved
       changes are written straight to the project).
     - app/new-project.html in edit mode — after dropping new documents
       into an upload zone (approved changes fill the form; the person
       still saves it).

   The documents go through the same AI agent as the "Cargar desde PDF"
   autofill (api/extract-project-data.js). Every project field where a
   document states something different from `current` is listed, current
   vs. proposed, for the person to tick; only onApply() writes anything.

   Requires assets/platform.js (INAPlatform) loaded first. */
(function () {
  function escHtml(s) {
    return String(s == null ? '' : s).replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
  }

  // Word-level diff for long text (description): removed words struck
  // through on the "current" side, added words highlighted on the "new" one.
  function wordDiffHtml(oldText, newText) {
    const a = String(oldText || '').split(/(\s+)/).filter((w) => w !== '');
    const b = String(newText || '').split(/(\s+)/).filter((w) => w !== '');
    if (a.length * b.length > 400000) {
      return { oldHtml: escHtml(oldText), newHtml: escHtml(newText) };
    }
    const dp = Array.from({ length: a.length + 1 }, () => new Uint16Array(b.length + 1));
    for (let i = a.length - 1; i >= 0; i--) {
      for (let j = b.length - 1; j >= 0; j--) {
        dp[i][j] = a[i] === b[j] ? dp[i + 1][j + 1] + 1 : Math.max(dp[i + 1][j], dp[i][j + 1]);
      }
    }
    let i = 0; let j = 0; let oldHtml = ''; let newHtml = '';
    while (i < a.length && j < b.length) {
      if (a[i] === b[j]) { oldHtml += escHtml(a[i]); newHtml += escHtml(b[j]); i++; j++; }
      else if (dp[i + 1][j] >= dp[i][j + 1]) { oldHtml += `<del style="background:rgba(200,60,60,.15);">${escHtml(a[i])}</del>`; i++; }
      else { newHtml += `<ins style="background:rgba(60,160,90,.18); text-decoration:none;">${escHtml(b[j])}</ins>`; j++; }
    }
    for (; i < a.length; i++) oldHtml += `<del style="background:rgba(200,60,60,.15);">${escHtml(a[i])}</del>`;
    for (; j < b.length; j++) newHtml += `<ins style="background:rgba(60,160,90,.18); text-decoration:none;">${escHtml(b[j])}</ins>`;
    return { oldHtml, newHtml };
  }

  /* opts:
       title, subtitleHtml       — modal header
       sources                   — [{ file, category }] (a File in hand) or
                                   [{ doc }] (a project_documents row, read
                                   back from Storage)
       current                   — object keyed by projects column
       intro(n)                  — text above the table (n = changes found)
       applyLabel(n)             — button text for n ticked changes
       allowApplyWithoutChanges  — show the button even with nothing to
                                   apply (the "updated version" flow still
                                   has a document to save)
       noChangesText             — shown when the AI finds no differences
       onApply(picked, info)     — async; throw to show the error in the
                                   modal. info.unreadable = no text read.
       onClose()                 — optional, runs whenever the modal closes
     Returns nothing; the modal closes itself after a successful onApply. */
  function open(opts) {
    const l = INAPlatform.currentLang();
    const es = l === 'es';
    const overlay = document.createElement('div');
    overlay.className = 'risk-form-overlay';
    overlay.innerHTML = `
      <div class="risk-form-panel" style="max-width:920px;">
        <div style="display:flex; justify-content:space-between; align-items:center; gap:12px; margin-bottom:8px;">
          <h3 style="margin:0;">${escHtml(opts.title)}</h3>
          <button type="button" class="btn ghost small" data-act="close">&times;</button>
        </div>
        <p style="font-size:13px; color:var(--muted); margin:0 0 16px;">${opts.subtitleHtml || ''}</p>
        <div data-role="body"><p style="font-size:13.5px; color:var(--muted);">${es
          ? 'La IA está leyendo el documento y comparándolo con los datos del proyecto… puede tardar hasta un minuto.'
          : 'The AI is reading the document and comparing it with the project data… this can take up to a minute.'}</p></div>
        <div data-role="actions" style="display:none; gap:12px; margin-top:20px; align-items:center; flex-wrap:wrap;">
          <button type="button" class="btn amber" data-act="apply"></button>
          <button type="button" class="btn ghost" data-act="close" data-role="cancel">${es ? 'Cancelar' : 'Cancel'}</button>
          <p data-role="note" class="contact-note" style="margin:0;"></p>
        </div>
      </div>`;
    document.body.appendChild(overlay);

    const tempPaths = [];
    let busy = false;
    const close = () => {
      if (busy) return;
      overlay.remove();
      tempPaths.forEach((p) => INAPlatform.deleteTempExtractionFile(p));
      if (opts.onClose) opts.onClose();
    };
    overlay.querySelectorAll('[data-act="close"]').forEach((b) => b.addEventListener('click', close));

    const body = overlay.querySelector('[data-role="body"]');
    const actions = overlay.querySelector('[data-role="actions"]');
    const applyBtn = overlay.querySelector('[data-act="apply"]');
    const cancelBtn = overlay.querySelector('[data-role="cancel"]');
    const note = overlay.querySelector('[data-role="note"]');

    (async () => {
      let changes = [];
      let unreadable = false;
      try {
        const files = [];
        for (const s of opts.sources) {
          const file = s.file || await INAPlatform.downloadDocumentAsFile(s.doc);
          const storagePath = await INAPlatform.uploadTempExtractionFile(file);
          tempPaths.push(storagePath);
          files.push({ storagePath, fileName: file.name, category: s.category || (s.doc && s.doc.document_type) || 'other' });
        }
        const result = await INAPlatform.extractProjectData(files);
        if (!(result.documentsUsed || []).length) {
          unreadable = true;
          body.innerHTML = `<p style="font-size:13.5px;">${es
            ? 'No se pudo leer texto de este documento (puede ser un PDF escaneado o un archivo que no es PDF), así que no se detectaron datos.'
            : "Couldn't read any text from this document (it may be a scanned PDF or not a PDF), so no data was detected."}</p>`;
        } else {
          changes = INAPlatform.diffProjectAgainstExtraction(opts.current || {}, result.fields || {});
        }
      } catch (err) {
        body.innerHTML = `<p class="contact-note">${escHtml((es ? 'No se pudo analizar el documento: ' : "Couldn't analyze the document: ") + (err.message || err))}</p>`;
        return;
      } finally {
        // Extraction is done (or failed) — the temp copies aren't needed
        // anymore, whatever the person does next.
        tempPaths.splice(0).forEach((p) => INAPlatform.deleteTempExtractionFile(p));
      }

      if (changes.length) {
        const intro = opts.intro ? opts.intro(changes.length) : (es
          ? `El documento tiene <b>${changes.length}</b> dato(s) distintos de los cargados en el proyecto. Marcá los que querés aplicar; los demás quedan como están.`
          : `The document has <b>${changes.length}</b> field(s) that differ from the project data. Tick the ones to apply; the rest stay as they are.`);
        body.innerHTML = `
          <p style="font-size:13px; margin:0 0 12px;">${intro}</p>
          <div style="overflow-x:auto;">
          <table class="risk-table">
            <thead><tr>
              <th style="width:28px;"><input type="checkbox" data-role="all" checked></th>
              <th>${es ? 'Dato' : 'Field'}</th>
              <th>${es ? 'Valor actual' : 'Current value'}</th>
              <th>${es ? 'Según el documento' : 'Per the document'}</th>
            </tr></thead>
            <tbody>${changes.map((c, idx) => {
              const label = c.field[l] || c.field.en;
              let cur; let next;
              if (c.field.kind === 'textarea') {
                const d = wordDiffHtml(c.current, c.proposed);
                cur = d.oldHtml || '—'; next = d.newHtml;
              } else {
                cur = escHtml(INAPlatform.formatProjectFieldValue(c.field, c.current));
                next = `<b>${escHtml(INAPlatform.formatProjectFieldValue(c.field, c.proposed))}</b>`;
              }
              // Renaming the project is opt-in; everything else starts ticked.
              const checked = c.field.key === 'name' ? '' : 'checked';
              return `<tr>
                <td style="vertical-align:top;"><input type="checkbox" data-idx="${idx}" ${checked}></td>
                <td style="vertical-align:top; white-space:nowrap;"><b>${escHtml(label)}</b></td>
                <td style="vertical-align:top; color:var(--muted); font-size:12.5px; line-height:1.5;">${cur}</td>
                <td style="vertical-align:top; font-size:12.5px; line-height:1.5;">${next}</td>
              </tr>`;
            }).join('')}</tbody>
          </table>
          </div>`;
        const all = body.querySelector('[data-role="all"]');
        all.addEventListener('change', () => body.querySelectorAll('input[data-idx]').forEach((c) => { c.checked = all.checked; }));
      } else if (!unreadable) {
        body.innerHTML = `<p style="font-size:13.5px;">${opts.noChangesText || (es
          ? 'La IA no encontró en el documento datos distintos de los ya cargados en el proyecto.'
          : 'The AI found nothing in the document that differs from the project data on file.')}</p>`;
      }

      if (!changes.length && !opts.allowApplyWithoutChanges) {
        applyBtn.style.display = 'none';
        cancelBtn.textContent = es ? 'Cerrar' : 'Close';
      }
      const refreshApplyLabel = () => {
        const n = body.querySelectorAll('input[data-idx]:checked').length;
        applyBtn.textContent = opts.applyLabel(n);
        if (!opts.allowApplyWithoutChanges) applyBtn.disabled = n === 0;
      };
      body.addEventListener('change', refreshApplyLabel);
      refreshApplyLabel();
      actions.style.display = 'flex';

      applyBtn.addEventListener('click', async () => {
        const picked = [...body.querySelectorAll('input[data-idx]:checked')].map((c) => changes[Number(c.dataset.idx)]);
        busy = true;
        applyBtn.disabled = true;
        note.textContent = es ? 'Guardando…' : 'Saving…';
        try {
          await opts.onApply(picked, { unreadable });
          busy = false;
          close();
        } catch (err) {
          busy = false;
          applyBtn.disabled = false;
          note.textContent = (es ? 'No se pudo guardar: ' : "Couldn't save: ") + (err.message || err);
        }
      });
    })();
  }

  window.ProjectDataReview = { open, escHtml };
})();
