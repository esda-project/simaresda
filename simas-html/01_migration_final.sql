-- ================================================================
-- SIMARESDA — MIGRATION FINAL (v5)
-- Perbaikan: semua enum TANPA schema prefix "public."
-- Berdasarkan inspect aktual: tidak ada enum di schema public
-- ================================================================
-- Jalankan di Supabase SQL Editor
-- Aman dijalankan pada database existing (IF NOT EXISTS semua)
-- ================================================================


-- ================================================================
-- BLOK 1: BUAT ENUM YANG BELUM ADA
-- Semua enum tanpa prefix schema (sesuai kondisi database)
-- ================================================================

-- Enum existing yang perlu dicek dulu sebelum dipakai:
-- role_user, status_arsip, status_pinjam, status_musna,
-- status_surat_masuk, status_surat_keluar,
-- kategori_arsip, sifat_surat, jenis_arsip

-- Buat enum existing jika belum ada (jaga-jaga)
DO $$ BEGIN
  CREATE TYPE role_user AS ENUM ('Admin', 'TU', 'Pengelola');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE status_arsip AS ENUM ('Aktif', 'Inaktif', 'Dipindah', 'Dimusnahkan');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE status_pinjam AS ENUM ('Dipinjam', 'Dikembalikan', 'Terlambat');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE status_musna AS ENUM ('Menunggu', 'Disetujui', 'Ditolak', 'Selesai');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE status_surat_masuk AS ENUM ('Disposisi', 'Diproses', 'Selesai', 'Arsip');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE status_surat_keluar AS ENUM ('Draft', 'Terkirim', 'Dibatalkan');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE kategori_arsip AS ENUM ('Umum', 'Keuangan', 'Kepegawaian', 'Teknis', 'Rahasia');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE sifat_surat AS ENUM ('Biasa', 'Penting', 'Segera', 'Rahasia');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE jenis_arsip AS ENUM ('Arsip Aktif', 'Arsip Inaktif');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- Tambah nilai 'Unit Kearsipan' ke role_user
ALTER TYPE role_user ADD VALUE IF NOT EXISTS 'Unit Kearsipan';

-- Enum BARU yang belum ada sama sekali
DO $$ BEGIN
  CREATE TYPE bidang_enum AS ENUM (
    'UMUM', 'BUMD', 'PEREKONOMIAN', 'SDA_DBHCHT'
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE jenis_penyusutan_enum AS ENUM (
    'Pemindahan', 'Pemusnahan', 'Penyerahan Permanen'
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE jenis_regulasi_enum AS ENUM (
    'UU', 'PP', 'Peraturan ANRI', 'Permendagri',
    'Perda', 'Perwali', 'Surat Edaran'
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;


-- ================================================================
-- BLOK 2: FUNGSI HELPER
-- ================================================================

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

-- Auto-insert profile saat user baru dibuat di Supabase Auth
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  INSERT INTO public.profiles (id, nama_lengkap, role)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email),
    'TU'
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();


-- ================================================================
-- BLOK 3: ALTER TABLE profiles
-- Sudah ada: id, nama_lengkap, jabatan, nip, role(role_user),
--   unit_kerja, is_active, avatar_url, last_login,
--   created_at, updated_at
-- Tambah: bidang, phone
-- ================================================================

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS bidang  bidang_enum,
  ADD COLUMN IF NOT EXISTS phone   TEXT;

COMMENT ON COLUMN public.profiles.bidang IS
  'Wajib diisi untuk role Pengelola. NULL untuk Admin, TU, Unit Kearsipan.';


-- ================================================================
-- BLOK 4: ALTER TABLE surat_masuk
-- Sudah ada: id, nomor_agenda, nomor_surat, tanggal_surat,
--   tanggal_terima, asal_surat, perihal, kategori, sifat,
--   status, keterangan, file_url, disposisi_ke,
--   created_by, updated_by, created_at, updated_at, is_deleted
-- Tambah: bidang, catatan_disposisi, tanggal_disposisi,
--   disposisi_oleh, file_lampiran_urls, jumlah_lampiran, is_rahasia
-- ================================================================

ALTER TABLE public.surat_masuk
  ADD COLUMN IF NOT EXISTS bidang              bidang_enum,
  ADD COLUMN IF NOT EXISTS catatan_disposisi   TEXT,
  ADD COLUMN IF NOT EXISTS tanggal_disposisi   TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS disposisi_oleh      UUID
      REFERENCES public.profiles(id),
  ADD COLUMN IF NOT EXISTS file_lampiran_urls  TEXT[],
  ADD COLUMN IF NOT EXISTS jumlah_lampiran     SMALLINT  DEFAULT 0,
  ADD COLUMN IF NOT EXISTS is_rahasia          BOOLEAN   NOT NULL DEFAULT FALSE;

-- FK ke profiles untuk kolom disposisi_ke yang sudah ada
DO $$ BEGIN
  ALTER TABLE public.surat_masuk
    ADD CONSTRAINT fk_sm_disposisi_ke
    FOREIGN KEY (disposisi_ke) REFERENCES public.profiles(id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE INDEX IF NOT EXISTS idx_sm_bidang         ON public.surat_masuk(bidang);
CREATE INDEX IF NOT EXISTS idx_sm_disposisi_ke   ON public.surat_masuk(disposisi_ke);
CREATE INDEX IF NOT EXISTS idx_sm_tanggal_terima ON public.surat_masuk(tanggal_terima);
CREATE INDEX IF NOT EXISTS idx_sm_status         ON public.surat_masuk(status);


-- ================================================================
-- BLOK 5: ALTER TABLE surat_keluar
-- Sudah ada: id, nomor_agenda, nomor_surat, tanggal_surat,
--   tujuan, perihal, kategori, sifat, status, penandatangan,
--   tembusan, keterangan, file_url,
--   created_by, updated_by, created_at, updated_at, is_deleted
-- Tambah: bidang, unit_pengelola, file_draft_url, file_final_url,
--   catatan_verifikasi, diverifikasi_oleh, tanggal_verifikasi,
--   diberi_nomor_oleh, tanggal_penomoran, is_rahasia
-- ================================================================

ALTER TABLE public.surat_keluar
  ADD COLUMN IF NOT EXISTS bidang              bidang_enum,
  ADD COLUMN IF NOT EXISTS unit_pengelola      UUID
      REFERENCES public.profiles(id),
  ADD COLUMN IF NOT EXISTS file_draft_url      TEXT,
  ADD COLUMN IF NOT EXISTS file_final_url      TEXT,
  ADD COLUMN IF NOT EXISTS catatan_verifikasi  TEXT,
  ADD COLUMN IF NOT EXISTS diverifikasi_oleh   UUID
      REFERENCES public.profiles(id),
  ADD COLUMN IF NOT EXISTS tanggal_verifikasi  TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS diberi_nomor_oleh   UUID
      REFERENCES public.profiles(id),
  ADD COLUMN IF NOT EXISTS tanggal_penomoran   TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS is_rahasia          BOOLEAN   NOT NULL DEFAULT FALSE;

CREATE INDEX IF NOT EXISTS idx_sk_bidang  ON public.surat_keluar(bidang);
CREATE INDEX IF NOT EXISTS idx_sk_status  ON public.surat_keluar(status);
CREATE INDEX IF NOT EXISTS idx_sk_tanggal ON public.surat_keluar(tanggal_surat);


-- ================================================================
-- BLOK 6: ALTER TABLE arsip
-- Sudah ada: id, kode_arsip, perihal, tahun_arsip, kategori,
--   status, jenis, lokasi_rak, lokasi_box, lokasi_laci,
--   retensi_aktif, retensi_inaktif, retensi_is_permanen,
--   nasib_akhir, deskripsi, file_url, surat_masuk_id,
--   surat_keluar_id, created_by, updated_by,
--   created_at, updated_at, deleted_at, is_deleted
-- Tambah: bidang, file_urls, diserahkan_oleh,
--   diterima_oleh, tanggal_inaktif
-- ================================================================

ALTER TABLE public.arsip
  ADD COLUMN IF NOT EXISTS bidang           bidang_enum,
  ADD COLUMN IF NOT EXISTS file_urls        TEXT[],
  ADD COLUMN IF NOT EXISTS diserahkan_oleh  UUID
      REFERENCES public.profiles(id),
  ADD COLUMN IF NOT EXISTS diterima_oleh    UUID
      REFERENCES public.profiles(id),
  ADD COLUMN IF NOT EXISTS tanggal_inaktif  DATE;

-- FK ke surat_masuk & surat_keluar jika belum ada
DO $$ BEGIN
  ALTER TABLE public.arsip
    ADD CONSTRAINT fk_arsip_surat_masuk
    FOREIGN KEY (surat_masuk_id) REFERENCES public.surat_masuk(id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  ALTER TABLE public.arsip
    ADD CONSTRAINT fk_arsip_surat_keluar
    FOREIGN KEY (surat_keluar_id) REFERENCES public.surat_keluar(id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE INDEX IF NOT EXISTS idx_arsip_bidang ON public.arsip(bidang);
CREATE INDEX IF NOT EXISTS idx_arsip_status ON public.arsip(status);
CREATE INDEX IF NOT EXISTS idx_arsip_tahun  ON public.arsip(tahun_arsip);
CREATE INDEX IF NOT EXISTS idx_arsip_kode   ON public.arsip(kode_arsip);


-- ================================================================
-- BLOK 7: ALTER TABLE peminjaman_arsip
-- Sudah ada: id, nomor_formulir, arsip_id, nama_peminjam,
--   jabatan_peminjam, nip_peminjam, unit_peminjam, keperluan,
--   tanggal_pinjam, tanggal_kembali_rencana, tanggal_kembali_aktual,
--   status, disetujui_oleh, dikembalikan_oleh, catatan,
--   created_by, created_at, updated_at
-- Tambah: peminjam_id, instansi_peminjam, dilayani_oleh
-- ================================================================

ALTER TABLE public.peminjaman_arsip
  ADD COLUMN IF NOT EXISTS peminjam_id        UUID
      REFERENCES public.profiles(id),
  ADD COLUMN IF NOT EXISTS instansi_peminjam  TEXT,
  ADD COLUMN IF NOT EXISTS dilayani_oleh      UUID
      REFERENCES public.profiles(id);

-- FK ke arsip jika belum ada
DO $$ BEGIN
  ALTER TABLE public.peminjaman_arsip
    ADD CONSTRAINT fk_pinjam_arsip
    FOREIGN KEY (arsip_id) REFERENCES public.arsip(id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE INDEX IF NOT EXISTS idx_pinjam_arsip_id ON public.peminjaman_arsip(arsip_id);
CREATE INDEX IF NOT EXISTS idx_pinjam_status   ON public.peminjaman_arsip(status);
CREATE INDEX IF NOT EXISTS idx_pinjam_tgl      ON public.peminjaman_arsip(tanggal_pinjam);


-- ================================================================
-- BLOK 8: ALTER TABLE regulasi
-- Sudah ada: id, kode, judul, nomor, tahun, instansi,
--   ringkasan, file_url, link_url, is_active, urutan,
--   created_by, created_at, updated_at
-- Tambah: jenis, tentang
-- ================================================================

ALTER TABLE public.regulasi
  ADD COLUMN IF NOT EXISTS jenis    jenis_regulasi_enum,
  ADD COLUMN IF NOT EXISTS tentang  TEXT;

CREATE INDEX IF NOT EXISTS idx_reg_jenis ON public.regulasi(jenis);
CREATE INDEX IF NOT EXISTS idx_reg_tahun ON public.regulasi(tahun);


-- ================================================================
-- BLOK 9: CREATE TABLE penyusutan_arsip (tabel baru)
-- Satu-satunya tabel yang belum ada di database
-- ================================================================

CREATE TABLE IF NOT EXISTS public.penyusutan_arsip (
  id                    UUID                    PRIMARY KEY DEFAULT uuid_generate_v4(),
  arsip_id              UUID                    NOT NULL
      REFERENCES public.arsip(id),
  jenis_penyusutan      jenis_penyusutan_enum   NOT NULL,
  tanggal_usul          DATE                    NOT NULL DEFAULT CURRENT_DATE,
  tanggal_persetujuan   DATE,
  tanggal_pelaksanaan   DATE,
  status                status_musna            NOT NULL DEFAULT 'Menunggu',
  keterangan            TEXT,
  dasar_hukum           TEXT,
  diusulkan_oleh        UUID                    NOT NULL
      REFERENCES public.profiles(id),
  disetujui_oleh        UUID
      REFERENCES public.profiles(id),
  berita_acara_url      TEXT,
  created_at            TIMESTAMPTZ             NOT NULL DEFAULT NOW(),
  updated_at            TIMESTAMPTZ             NOT NULL DEFAULT NOW()
);

DROP TRIGGER IF EXISTS penyusutan_updated_at ON public.penyusutan_arsip;
CREATE TRIGGER penyusutan_updated_at
  BEFORE UPDATE ON public.penyusutan_arsip
  FOR EACH ROW EXECUTE PROCEDURE public.set_updated_at();

CREATE INDEX IF NOT EXISTS idx_susut_arsip_id ON public.penyusutan_arsip(arsip_id);
CREATE INDEX IF NOT EXISTS idx_susut_jenis    ON public.penyusutan_arsip(jenis_penyusutan);
CREATE INDEX IF NOT EXISTS idx_susut_status   ON public.penyusutan_arsip(status);


-- ================================================================
-- BLOK 10: VIEWS DASHBOARD
-- Nama kolom sesuai schema aktual:
--   arsip.perihal, arsip.tahun_arsip, arsip.status, arsip.jenis
--   surat_masuk.disposisi_ke, surat_masuk.status
--   surat_keluar.tanggal_surat
-- ================================================================

CREATE OR REPLACE VIEW public.v_statistik_surat_masuk AS
SELECT
  bidang,
  EXTRACT(YEAR  FROM tanggal_terima)::INTEGER AS tahun,
  EXTRACT(MONTH FROM tanggal_terima)::INTEGER AS bulan,
  COUNT(*) AS jumlah
FROM public.surat_masuk
WHERE bidang IS NOT NULL
  AND is_deleted = FALSE
GROUP BY bidang, tahun, bulan
ORDER BY tahun DESC, bulan DESC;

CREATE OR REPLACE VIEW public.v_statistik_surat_keluar AS
SELECT
  bidang,
  EXTRACT(YEAR  FROM tanggal_surat)::INTEGER AS tahun,
  EXTRACT(MONTH FROM tanggal_surat)::INTEGER AS bulan,
  COUNT(*) AS jumlah
FROM public.surat_keluar
WHERE bidang IS NOT NULL
  AND is_deleted = FALSE
GROUP BY bidang, tahun, bulan
ORDER BY tahun DESC, bulan DESC;

CREATE OR REPLACE VIEW public.v_statistik_arsip AS
SELECT
  bidang,
  status,
  jenis,
  COUNT(*) AS jumlah
FROM public.arsip
WHERE bidang IS NOT NULL
  AND is_deleted = FALSE
GROUP BY bidang, status, jenis;

CREATE OR REPLACE VIEW public.v_peminjaman_aktif AS
SELECT
  p.id,
  p.nama_peminjam,
  p.jabatan_peminjam,
  p.unit_peminjam,
  p.keperluan,
  p.tanggal_pinjam,
  p.tanggal_kembali_rencana,
  p.status,
  a.perihal      AS judul_arsip,
  a.kode_arsip,
  a.bidang,
  a.tahun_arsip,
  CASE
    WHEN p.tanggal_kembali_rencana < CURRENT_DATE THEN TRUE
    ELSE FALSE
  END AS terlambat
FROM public.peminjaman_arsip p
JOIN public.arsip a ON a.id = p.arsip_id
WHERE p.status = 'Dipinjam';

CREATE OR REPLACE VIEW public.v_dashboard_summary AS
SELECT
  (SELECT COUNT(*) FROM public.surat_masuk
   WHERE EXTRACT(YEAR FROM tanggal_terima) = EXTRACT(YEAR FROM NOW())
     AND is_deleted = FALSE)                           AS surat_masuk_tahun_ini,
  (SELECT COUNT(*) FROM public.surat_keluar
   WHERE EXTRACT(YEAR FROM tanggal_surat) = EXTRACT(YEAR FROM NOW())
     AND is_deleted = FALSE)                           AS surat_keluar_tahun_ini,
  (SELECT COUNT(*) FROM public.arsip
   WHERE status = 'Aktif' AND is_deleted = FALSE)      AS arsip_aktif,
  (SELECT COUNT(*) FROM public.arsip
   WHERE status = 'Inaktif' AND is_deleted = FALSE)    AS arsip_inaktif,
  (SELECT COUNT(*) FROM public.peminjaman_arsip
   WHERE status = 'Dipinjam')                          AS peminjaman_aktif,
  (SELECT COUNT(*) FROM public.penyusutan_arsip
   WHERE status = 'Menunggu')                          AS penyusutan_pending;


-- ================================================================
-- BLOK 11: GRANT PERMISSIONS
-- ================================================================

GRANT SELECT, INSERT, UPDATE ON public.profiles         TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.surat_masuk      TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.surat_keluar     TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.arsip            TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.peminjaman_arsip TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.penyusutan_arsip TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.regulasi         TO authenticated;

GRANT SELECT ON public.v_statistik_surat_masuk  TO authenticated;
GRANT SELECT ON public.v_statistik_surat_keluar TO authenticated;
GRANT SELECT ON public.v_statistik_arsip        TO authenticated;
GRANT SELECT ON public.v_peminjaman_aktif       TO authenticated;
GRANT SELECT ON public.v_dashboard_summary      TO authenticated;

-- ================================================================
-- SELESAI — Lanjutkan dengan 02_rls_final.sql
-- ================================================================
