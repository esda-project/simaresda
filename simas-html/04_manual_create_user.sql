-- ============================================================
-- SIMAS - Alternatif: Buat User Admin Tanpa Trigger
-- Gunakan cara ini jika masih error setelah fix trigger
--
-- CARA PAKAI:
-- 1. Jalankan file ini di SQL Editor
-- 2. Pergi ke Authentication > Users > Add user
-- 3. Isi email + password + centang "Auto Confirm User"
-- 4. Salin UUID user yang muncul
-- 5. Jalankan query UPDATE di bawah dengan UUID tersebut
-- ============================================================

-- ── QUERY 1: Cek apakah user sudah ada di profiles ──────────
-- Jalankan setelah buat user di Auth Dashboard
-- Ganti 'EMAIL_ANDA@instansi.go.id' dengan email yang dipakai

SELECT
  au.id,
  au.email,
  au.created_at,
  p.id        AS profile_id,
  p.nama_lengkap,
  p.role,
  p.is_active
FROM auth.users au
LEFT JOIN public.profiles p ON p.id = au.id
WHERE au.email = 'EMAIL_ANDA@instansi.go.id';

-- ── QUERY 2: Insert manual ke profiles jika belum ada ───────
-- Jalankan ini HANYA jika kolom profile_id di atas kosong (NULL)
-- Ganti UUID_USER dan email sesuai milik Anda

/*
INSERT INTO public.profiles (
  id,
  nama_lengkap,
  jabatan,
  role,
  is_active,
  created_at,
  updated_at
)
VALUES (
  'UUID_USER_ANDA',          -- UUID dari Authentication > Users
  'Administrator Sistem',    -- Nama lengkap
  'Kepala Unit Kearsipan',   -- Jabatan
  'Admin',                   -- Role: Admin / Pengelola / TU
  TRUE,
  NOW(),
  NOW()
)
ON CONFLICT (id) DO UPDATE
SET
  nama_lengkap = EXCLUDED.nama_lengkap,
  jabatan      = EXCLUDED.jabatan,
  role         = EXCLUDED.role,
  is_active    = TRUE,
  updated_at   = NOW();
*/

-- ── QUERY 3: Update role jika profile sudah ada tapi role salah
/*
UPDATE public.profiles
SET
  nama_lengkap = 'Administrator Sistem',
  jabatan      = 'Kepala Unit Kearsipan',
  role         = 'Admin',
  is_active    = TRUE,
  updated_at   = NOW()
WHERE id = 'UUID_USER_ANDA';
*/

-- ── QUERY 4: Verifikasi akhir ────────────────────────────────
SELECT
  p.id,
  p.nama_lengkap,
  p.role,
  p.is_active,
  au.email
FROM public.profiles p
JOIN auth.users au ON au.id = p.id
ORDER BY p.created_at DESC
LIMIT 10;
