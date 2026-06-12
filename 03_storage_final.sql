-- ================================================================
-- SIMARESDA — STORAGE SETUP FINAL
-- Jalankan setelah 02_rls_final.sql
-- Atau buat bucket via Supabase Dashboard → Storage
-- ================================================================


-- ================================================================
-- BUAT BUCKET (jalankan di SQL Editor Supabase)
-- ================================================================

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES
  (
    'naskah-masuk', 'naskah-masuk', false,
    20971520, -- 20 MB
    ARRAY[
      'application/pdf',
      'image/jpeg','image/png','image/webp',
      'application/msword',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
    ]
  ),
  (
    'naskah-keluar', 'naskah-keluar', false,
    20971520,
    ARRAY[
      'application/pdf',
      'image/jpeg','image/png','image/webp',
      'application/msword',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
    ]
  ),
  (
    'arsip', 'arsip', false,
    52428800, -- 50 MB
    ARRAY[
      'application/pdf',
      'image/jpeg','image/png','image/webp',
      'application/msword',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'application/vnd.ms-excel',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    ]
  ),
  (
    'regulasi', 'regulasi', false,
    52428800,
    ARRAY['application/pdf']
  )
ON CONFLICT (id) DO NOTHING;


-- ================================================================
-- STORAGE POLICIES — naskah-masuk
-- ================================================================

DROP POLICY IF EXISTS "sm_storage_admin"    ON storage.objects;
DROP POLICY IF EXISTS "sm_storage_tu"       ON storage.objects;
DROP POLICY IF EXISTS "sm_storage_up_read"  ON storage.objects;
DROP POLICY IF EXISTS "sm_storage_ks_read"  ON storage.objects;

-- Admin: full
CREATE POLICY "sm_storage_admin" ON storage.objects
  FOR ALL TO authenticated
  USING (bucket_id = 'naskah-masuk' AND public.is_admin())
  WITH CHECK (bucket_id = 'naskah-masuk' AND public.is_admin());

-- TU: full (upload, read, delete)
CREATE POLICY "sm_storage_tu" ON storage.objects
  FOR ALL TO authenticated
  USING (bucket_id = 'naskah-masuk' AND public.is_tu())
  WITH CHECK (bucket_id = 'naskah-masuk' AND public.is_tu());

-- Pengelola: baca file di folder bidangnya
-- Konvensi path: naskah-masuk/{bidang}/{tahun}/{file}
CREATE POLICY "sm_storage_up_read" ON storage.objects
  FOR SELECT TO authenticated
  USING (
    bucket_id = 'naskah-masuk'
    AND public.is_pengelola()
    AND (storage.foldername(name))[1] = LOWER(public.get_my_bidang()::TEXT)
  );

-- Unit Kearsipan: baca semua
CREATE POLICY "sm_storage_ks_read" ON storage.objects
  FOR SELECT TO authenticated
  USING (bucket_id = 'naskah-masuk' AND public.is_kearsipan());


-- ================================================================
-- STORAGE POLICIES — naskah-keluar
-- ================================================================

DROP POLICY IF EXISTS "sk_storage_admin"   ON storage.objects;
DROP POLICY IF EXISTS "sk_storage_tu"      ON storage.objects;
DROP POLICY IF EXISTS "sk_storage_up_rw"   ON storage.objects;
DROP POLICY IF EXISTS "sk_storage_ks_read" ON storage.objects;

CREATE POLICY "sk_storage_admin" ON storage.objects
  FOR ALL TO authenticated
  USING (bucket_id = 'naskah-keluar' AND public.is_admin())
  WITH CHECK (bucket_id = 'naskah-keluar' AND public.is_admin());

CREATE POLICY "sk_storage_tu" ON storage.objects
  FOR ALL TO authenticated
  USING (bucket_id = 'naskah-keluar' AND public.is_tu())
  WITH CHECK (bucket_id = 'naskah-keluar' AND public.is_tu());

-- Pengelola: upload & baca di folder bidangnya
CREATE POLICY "sk_storage_up_rw" ON storage.objects
  FOR ALL TO authenticated
  USING (
    bucket_id = 'naskah-keluar'
    AND public.is_pengelola()
    AND (storage.foldername(name))[1] = LOWER(public.get_my_bidang()::TEXT)
  )
  WITH CHECK (
    bucket_id = 'naskah-keluar'
    AND public.is_pengelola()
    AND (storage.foldername(name))[1] = LOWER(public.get_my_bidang()::TEXT)
  );

CREATE POLICY "sk_storage_ks_read" ON storage.objects
  FOR SELECT TO authenticated
  USING (bucket_id = 'naskah-keluar' AND public.is_kearsipan());


-- ================================================================
-- STORAGE POLICIES — arsip
-- ================================================================

DROP POLICY IF EXISTS "arsip_storage_admin"    ON storage.objects;
DROP POLICY IF EXISTS "arsip_storage_tu_read"  ON storage.objects;
DROP POLICY IF EXISTS "arsip_storage_up_rw"    ON storage.objects;
DROP POLICY IF EXISTS "arsip_storage_ks_all"   ON storage.objects;

CREATE POLICY "arsip_storage_admin" ON storage.objects
  FOR ALL TO authenticated
  USING (bucket_id = 'arsip' AND public.is_admin())
  WITH CHECK (bucket_id = 'arsip' AND public.is_admin());

CREATE POLICY "arsip_storage_tu_read" ON storage.objects
  FOR SELECT TO authenticated
  USING (bucket_id = 'arsip' AND public.is_tu());

CREATE POLICY "arsip_storage_up_rw" ON storage.objects
  FOR ALL TO authenticated
  USING (
    bucket_id = 'arsip'
    AND public.is_pengelola()
    AND (storage.foldername(name))[1] = LOWER(public.get_my_bidang()::TEXT)
  )
  WITH CHECK (
    bucket_id = 'arsip'
    AND public.is_pengelola()
    AND (storage.foldername(name))[1] = LOWER(public.get_my_bidang()::TEXT)
  );

CREATE POLICY "arsip_storage_ks_all" ON storage.objects
  FOR ALL TO authenticated
  USING (bucket_id = 'arsip' AND public.is_kearsipan())
  WITH CHECK (bucket_id = 'arsip' AND public.is_kearsipan());


-- ================================================================
-- STORAGE POLICIES — regulasi
-- ================================================================

DROP POLICY IF EXISTS "reg_storage_admin"    ON storage.objects;
DROP POLICY IF EXISTS "reg_storage_all_read" ON storage.objects;

CREATE POLICY "reg_storage_admin" ON storage.objects
  FOR ALL TO authenticated
  USING (bucket_id = 'regulasi' AND public.is_admin())
  WITH CHECK (bucket_id = 'regulasi' AND public.is_admin());

-- Semua user terautentikasi: baca file regulasi
CREATE POLICY "reg_storage_all_read" ON storage.objects
  FOR SELECT TO authenticated
  USING (bucket_id = 'regulasi');


-- ================================================================
-- KONVENSI PENAMAAN FILE DI STORAGE
-- ================================================================
--
-- Bucket: naskah-masuk
--   /{bidang_lower}/{yyyy}/{nomor_agenda}_{nama_file}.pdf
--   Contoh: /umum/2025/SM-001-2025_undangan_rapat.pdf
--           /perekonomian/2025/SM-045-2025_lampiran_1.pdf
--
-- Bucket: naskah-keluar
--   /{bidang_lower}/{yyyy}/{nomor_agenda}_{draft|final}.pdf
--   Contoh: /bumd/2025/SK-012-2025_draft.pdf
--           /bumd/2025/SK-012-2025_final.pdf
--
-- Bucket: arsip
--   /{bidang_lower}/{yyyy}/{kode_arsip}_{perihal_singkat}.pdf
--   Contoh: /sda_dbhcht/2024/800.1.2_laporan_realisasi_dbh_cht.pdf
--
-- Bucket: regulasi
--   /{jenis_lower}/{nomor_singkat}_{tahun}.pdf
--   Contoh: /uu/UU-43-2009.pdf
--           /peraturan_anri/ANRI-9-2018.pdf
--
-- Nilai bidang_lower:
--   UMUM       → umum
--   BUMD       → bumd
--   PEREKONOMIAN → perekonomian
--   SDA_DBHCHT → sda_dbhcht
--
-- ================================================================
-- SELESAI
-- ================================================================
