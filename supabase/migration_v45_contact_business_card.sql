-- ============================================================================
-- Migration v45: Tarjeta de presentación (business card) por Contacto
--
-- QUÉ AGREGA
-- Permite crear un Contacto en Master Data subiendo la foto de su tarjeta de
-- presentación: app/master-data.html manda la imagen a la nueva función
-- api/extract-business-card.js (usa Claude/Anthropic con visión — es el
-- único proveedor de los configurados en esta plataforma que lee imágenes,
-- ver el comentario en ese archivo), que devuelve nombre, cargo, email,
-- teléfono y el nombre de la empresa/organismo detectado. El formulario de
-- Contacto se pre-completa con esos datos para que Pablo los revise/edite
-- antes de guardar — nunca se guarda nada sin pasar por el botón "Guardar".
--
-- Si la empresa/organismo detectado no existe todavía en Master Data, el
-- formulario lo muestra como sugerencia (nombre editable + tipo/jurisdicción)
-- y solo se crea si Pablo confirma al guardar — decisión explícita de Pablo,
-- nunca automático sin revisión.
--
-- La imagen de la tarjeta se guarda como adjunto del contacto (decisión
-- explícita de Pablo, para poder verla después) — este archivo agrega:
--   1. public.contacts.business_card_path — ruta del archivo en Supabase
--      Storage (mismo bucket "project-documents" que ya existe, reutilizado
--      bajo un prefijo "master-data/" en vez de crear un bucket nuevo — ver
--      el comentario en migration_v27 sobre por qué reutilizar el bucket
--      project-documents en vez de crear uno por feature es el patrón ya
--      usado en program_documents).
--   2. Políticas de Storage para ese prefijo "master-data/", gateadas a
--      advisor/admin (igual que las 4 tablas de Master Data) — las políticas
--      existentes de "project-documents" (doc_upload_own_folder, etc.) están
--      pensadas para carpetas {user_id}/... de documentos de PROYECTOS, no
--      sirven para este caso (Master Data no tiene dueño), así que son
--      políticas nuevas y separadas, no una reutilización de esas.
--
-- CÓMO USAR
-- 1. Ejecutar este archivo una sola vez en el SQL Editor de Supabase (usa
--    "if not exists"/"drop policy if exists", es seguro correrlo más de
--    una vez).
-- 2. No hace falta crear ningún bucket nuevo — "project-documents" ya
--    existe (se creó en migration_v1 aprox., ver schema.sql).
-- 3. En Vercel, agregar (si todavía no está) la env var ANTHROPIC_API_KEY —
--    es la misma que ya usás si LLM_PROVIDER=anthropic para el Análisis IA
--    de proyectos; si tenés LLM_PROVIDER en otro valor (groq/bedrock/local)
--    para el análisis de proyectos, esta función de tarjetas de presentación
--    IGUAL necesita ANTHROPIC_API_KEY configurada aparte, porque es la única
--    que lee imágenes en este código — ver el comentario al inicio de
--    api/extract-business-card.js.
-- ============================================================================

alter table public.contacts add column if not exists business_card_path text;

comment on column public.contacts.business_card_path is
  'Ruta en Supabase Storage (bucket project-documents, prefijo master-data/contacts/) de la imagen de la tarjeta de presentación de este contacto, si se cargó una. Null si el contacto se creó a mano sin tarjeta.';

-- ---------- Storage: prefijo "master-data/" dentro de project-documents ----------
drop policy if exists "master_data_upload_advisor_or_admin" on storage.objects;
create policy "master_data_upload_advisor_or_admin" on storage.objects
  for insert with check (
    bucket_id = 'project-documents'
    and (storage.foldername(name))[1] = 'master-data'
    and (public.is_advisor() or public.is_admin())
  );

drop policy if exists "master_data_read_advisor_or_admin" on storage.objects;
create policy "master_data_read_advisor_or_admin" on storage.objects
  for select using (
    bucket_id = 'project-documents'
    and (storage.foldername(name))[1] = 'master-data'
    and (public.is_advisor() or public.is_admin())
  );

drop policy if exists "master_data_delete_advisor_or_admin" on storage.objects;
create policy "master_data_delete_advisor_or_admin" on storage.objects
  for delete using (
    bucket_id = 'project-documents'
    and (storage.foldername(name))[1] = 'master-data'
    and (public.is_advisor() or public.is_admin())
  );

-- Convención de ruta usada por assets/platform.js:
--   master-data/contacts/{contact_id}/{timestamp}_{filename}

-- ============================================================================
-- Verificación
-- ============================================================================
select column_name from information_schema.columns
where table_schema = 'public' and table_name = 'contacts' and column_name = 'business_card_path';

select policyname from pg_policies
where schemaname = 'storage' and tablename = 'objects' and policyname like 'master_data_%'
order by policyname;
