-- ================================================================
-- SIMARESDA — FIX SECURITY DEFINER VIEWS
-- Memperbaiki 5 view yang error di Supabase Security Lints
-- 
-- MASALAH:
-- Semua view dashboard dibuat dengan SECURITY DEFINER secara
-- implisit oleh Supabase. Artinya view berjalan dengan hak akses
-- PEMBUAT view (biasanya superuser), bukan hak akses USER yang
-- mengquery — sehingga RLS diabaikan dan semua user bisa lihat
-- semua data tanpa filter bidang.
--
-- SOLUSI:
-- Recreate semua view dengan SECURITY INVOKER (default yang benar)
-- sehingga RLS tetap aktif dan user hanya melihat data sesuai
-- hak aksesnya.
--
-- Jalankan di: Supabase → SQL Editor
-- ================================================================


-- ================================================================
-- DROP semua view lama terlebih dahulu
-- ================================================================

DROP VIEW IF EXISTS public.v_dashboard_summary;
DROP VIEW IF EXISTS public.v_peminjaman_aktif;
DROP VIEW IF EXISTS public.v_statistik_arsip;
DROP VIEW IF EXISTS public.v_statistik_surat_keluar;
DROP VIEW IF EXISTS public.v_statistik_surat_masuk;


-- ================================================================
-- RECREATE: v_statistik_surat_masuk
-- SECURITY INVOKER = RLS tetap aktif
-- ================================================================

CREATE OR REPLACE VIEW public.v_statistik_surat_masuk
WITH (security_invoker = true)
AS
SELECT
  bidang,
  EXTRACT(YEAR  FROM tanggal_terima)::INTEGER AS tahun,
  EXTRACT(MONTH FROM tanggal_terima)::INTEGER AS bulan,
  COUNT(*)                                    AS jumlah
FROM public.surat_masuk
WHERE is_deleted = FALSE
GROUP BY bidang, tahun, bulan
ORDER BY tahun DESC, bulan DESC;

-- Grant akses
GRANT SELECT ON public.v_statistik_surat_masuk TO authenticated;
GRANT SELECT ON public.v_statistik_surat_masuk TO anon;


-- ================================================================
-- RECREATE: v_statistik_surat_keluar
-- ================================================================

CREATE OR REPLACE VIEW public.v_statistik_surat_keluar
WITH (security_invoker = true)
AS
SELECT
  bidang,
  EXTRACT(YEAR  FROM COALESCE(tanggal_surat, created_at::DATE))::INTEGER AS tahun,
  EXTRACT(MONTH FROM COALESCE(tanggal_surat, created_at::DATE))::INTEGER AS bulan,
  COUNT(*)                                                                AS jumlah
FROM public.surat_keluar
WHERE is_deleted = FALSE
GROUP BY bidang, tahun, bulan
ORDER BY tahun DESC, bulan DESC;

GRANT SELECT ON public.v_statistik_surat_keluar TO authenticated;
GRANT SELECT ON public.v_statistik_surat_keluar TO anon;


-- ================================================================
-- RECREATE: v_statistik_arsip
-- ================================================================

CREATE OR REPLACE VIEW public.v_statistik_arsip
WITH (security_invoker = true)
AS
SELECT
  bidang,
  status,
  jenis,
  COUNT(*) AS jumlah
FROM public.arsip
WHERE is_deleted = FALSE
GROUP BY bidang, status, jenis;

GRANT SELECT ON public.v_statistik_arsip TO authenticated;
GRANT SELECT ON public.v_statistik_arsip TO anon;


-- ================================================================
-- RECREATE: v_peminjaman_aktif
-- ================================================================

CREATE OR REPLACE VIEW public.v_peminjaman_aktif
WITH (security_invoker = true)
AS
SELECT
  p.id,
  p.nomor_formulir,
  p.nama_peminjam,
  p.jabatan_peminjam,
  p.unit_peminjam,
  p.keperluan,
  p.tanggal_pinjam,
  p.tanggal_kembali_rencana,
  p.tanggal_kembali_aktual,
  p.status,
  a.perihal      AS judul_arsip,
  a.kode_arsip,
  a.bidang,
  a.tahun_arsip,
  CASE
    WHEN p.tanggal_kembali_rencana < CURRENT_DATE
     AND p.status = 'Dipinjam'
    THEN TRUE
    ELSE FALSE
  END AS terlambat
FROM public.peminjaman_arsip p
JOIN public.arsip a ON a.id = p.arsip_id
WHERE p.status = 'Dipinjam';

GRANT SELECT ON public.v_peminjaman_aktif TO authenticated;


-- ================================================================
-- RECREATE: v_dashboard_summary
-- ================================================================

CREATE OR REPLACE VIEW public.v_dashboard_summary
WITH (security_invoker = true)
AS
SELECT
  -- Surat masuk tahun ini
  (
    SELECT COUNT(*)
    FROM public.surat_masuk
    WHERE EXTRACT(YEAR FROM tanggal_terima) = EXTRACT(YEAR FROM NOW())
      AND is_deleted = FALSE
  ) AS surat_masuk_tahun_ini,

  -- Surat keluar tahun ini
  (
    SELECT COUNT(*)
    FROM public.surat_keluar
    WHERE EXTRACT(YEAR FROM created_at) = EXTRACT(YEAR FROM NOW())
      AND is_deleted = FALSE
  ) AS surat_keluar_tahun_ini,

  -- Arsip aktif
  (
    SELECT COUNT(*)
    FROM public.arsip
    WHERE status = 'Aktif'
      AND is_deleted = FALSE
  ) AS arsip_aktif,

  -- Arsip inaktif
  (
    SELECT COUNT(*)
    FROM public.arsip
    WHERE status = 'Inaktif'
      AND is_deleted = FALSE
  ) AS arsip_inaktif,

  -- Peminjaman aktif (belum dikembalikan)
  (
    SELECT COUNT(*)
    FROM public.peminjaman_arsip
    WHERE status = 'Dipinjam'
  ) AS peminjaman_aktif,

  -- Penyusutan pending (menunggu persetujuan)
  (
    SELECT COUNT(*)
    FROM public.penyusutan_arsip
    WHERE status = 'Menunggu'
  ) AS penyusutan_pending;

GRANT SELECT ON public.v_dashboard_summary TO authenticated;


-- ================================================================
-- VERIFIKASI: Pastikan semua view sudah SECURITY INVOKER
-- Jalankan query ini setelah semua view di-recreate
-- Hasilnya harus: security_type = 'invoker' untuk semua view
-- ================================================================

SELECT
  viewname,
  CASE
    WHEN definition ILIKE '%security_invoker%' THEN 'invoker ✓'
    ELSE 'definer ✗ (masih bermasalah)'
  END AS security_type
FROM pg_views
WHERE schemaname = 'public'
  AND viewname LIKE 'v_%'
ORDER BY viewname;

-- ================================================================
-- CATATAN PENTING:
-- Setelah menjalankan SQL ini, kembali ke:
-- Supabase → Database → Lints
-- dan klik "Refresh" untuk memverifikasi error sudah hilang.
--
-- Jika masih muncul error, tunggu beberapa menit lalu refresh lagi.
-- ================================================================
