-- ============================================================
-- SIMARESDA — INSPECT KOLOM TABEL EXISTING
-- Jalankan semua sekaligus, lalu paste hasilnya ke developer
-- ============================================================

SELECT
  table_name,
  column_name,
  data_type,
  udt_name,          -- nama enum jika data_type = 'USER-DEFINED'
  column_default,
  is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name IN (
    'profiles',
    'naskah_masuk',
    'naskah_keluar',
    'arsip',
    'peminjaman_arsip',
    'penyusutan_arsip',
    'regulasi',
    'activity_log'
  )
ORDER BY table_name, ordinal_position;
