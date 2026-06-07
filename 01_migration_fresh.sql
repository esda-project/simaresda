-- ================================================================
-- SIMARESDA — MIGRATION FRESH (dari nol)
-- Untuk project Supabase yang belum punya tabel apapun di public
-- Jalankan di: Supabase → SQL Editor
-- ================================================================
-- PENTING: Jalankan BLOK PER BLOK (copy-paste satu blok, Run,
--          lalu blok berikutnya). Jangan jalankan sekaligus.
-- ================================================================


-- ================================================================
-- BLOK 1: AKTIFKAN EXTENSION
-- ================================================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";


-- ================================================================
-- BLOK 2: BUAT SEMUA ENUM
-- (jalankan satu per satu jika error duplicate)
-- ================================================================

DO $$ BEGIN
  CREATE TYPE role_user AS ENUM (
    'Admin', 'TU', 'Pengelola', 'Unit Kearsipan'
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE bidang_enum AS ENUM (
    'UMUM', 'BUMD', 'PEREKONOMIAN', 'SDA_DBHCHT'
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE kategori_arsip AS ENUM (
    'Umum', 'Keuangan', 'Kepegawaian', 'Teknis', 'Rahasia'
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE sifat_surat AS ENUM (
    'Biasa', 'Penting', 'Segera', 'Rahasia'
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE jenis_arsip AS ENUM (
    'Arsip Aktif', 'Arsip Inaktif'
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE status_arsip AS ENUM (
    'Aktif', 'Inaktif', 'Dipindah', 'Dimusnahkan'
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE status_surat_masuk AS ENUM (
    'Disposisi', 'Diproses', 'Selesai', 'Arsip'
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE status_surat_keluar AS ENUM (
    'Draft', 'Terverifikasi', 'Terkirim', 'Dibatalkan'
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE status_pinjam AS ENUM (
    'Dipinjam', 'Dikembalikan', 'Terlambat'
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE status_musna AS ENUM (
    'Menunggu', 'Disetujui', 'Ditolak', 'Selesai'
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
-- BLOK 3: TABEL profiles
-- Extends auth.users Supabase
-- ================================================================

CREATE TABLE IF NOT EXISTS public.profiles (
  id           UUID          PRIMARY KEY
                             REFERENCES auth.users(id) ON DELETE CASCADE,
  nama_lengkap TEXT          NOT NULL DEFAULT '',
  nip          TEXT,
  jabatan      TEXT,
  unit_kerja   TEXT,
  role         role_user     NOT NULL DEFAULT 'TU',
  bidang       bidang_enum,
  is_active    BOOLEAN       NOT NULL DEFAULT TRUE,
  avatar_url   TEXT,
  phone        TEXT,
  last_login   TIMESTAMPTZ,
  created_at   TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE public.profiles IS
  'Profil pengguna SIMARESDA. id = auth.users.id';
COMMENT ON COLUMN public.profiles.bidang IS
  'Wajib untuk role Pengelola. NULL untuk Admin, TU, Unit Kearsipan.';


-- ================================================================
-- BLOK 4: FUNGSI & TRIGGER updated_at
-- ================================================================

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS profiles_updated_at ON public.profiles;
CREATE TRIGGER profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE PROCEDURE public.set_updated_at();

-- Auto-insert profile saat user baru dibuat di Supabase Auth
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public AS $$
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
-- BLOK 5: TABEL surat_masuk
-- ================================================================

CREATE TABLE IF NOT EXISTS public.surat_masuk (
  id                  UUID              PRIMARY KEY DEFAULT uuid_generate_v4(),
  nomor_agenda        TEXT              UNIQUE NOT NULL,
  nomor_surat         TEXT              NOT NULL,
  tanggal_surat       DATE              NOT NULL,
  tanggal_terima      DATE              NOT NULL DEFAULT CURRENT_DATE,
  asal_surat          TEXT              NOT NULL,
  perihal             TEXT              NOT NULL,
  bidang              bidang_enum       NOT NULL,
  kategori            kategori_arsip    NOT NULL DEFAULT 'Umum',
  sifat               sifat_surat       NOT NULL DEFAULT 'Biasa',
  status              status_surat_masuk NOT NULL DEFAULT 'Disposisi',
  keterangan          TEXT,
  file_url            TEXT,
  file_lampiran_urls  TEXT[],
  jumlah_lampiran     SMALLINT          DEFAULT 0,
  is_rahasia          BOOLEAN           NOT NULL DEFAULT FALSE,
  disposisi_ke        UUID              REFERENCES public.profiles(id),
  catatan_disposisi   TEXT,
  tanggal_disposisi   TIMESTAMPTZ,
  disposisi_oleh      UUID              REFERENCES public.profiles(id),
  is_deleted          BOOLEAN           NOT NULL DEFAULT FALSE,
  created_by          UUID              REFERENCES public.profiles(id),
  updated_by          UUID              REFERENCES public.profiles(id),
  created_at          TIMESTAMPTZ       NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ       NOT NULL DEFAULT NOW()
);

DROP TRIGGER IF EXISTS surat_masuk_updated_at ON public.surat_masuk;
CREATE TRIGGER surat_masuk_updated_at
  BEFORE UPDATE ON public.surat_masuk
  FOR EACH ROW EXECUTE PROCEDURE public.set_updated_at();

CREATE INDEX IF NOT EXISTS idx_sm_bidang   ON public.surat_masuk(bidang);
CREATE INDEX IF NOT EXISTS idx_sm_status   ON public.surat_masuk(status);
CREATE INDEX IF NOT EXISTS idx_sm_terima   ON public.surat_masuk(tanggal_terima);
CREATE INDEX IF NOT EXISTS idx_sm_disp     ON public.surat_masuk(disposisi_ke);
CREATE INDEX IF NOT EXISTS idx_sm_deleted  ON public.surat_masuk(is_deleted);


-- ================================================================
-- BLOK 6: TABEL surat_keluar
-- ================================================================

CREATE TABLE IF NOT EXISTS public.surat_keluar (
  id                  UUID                  PRIMARY KEY DEFAULT uuid_generate_v4(),
  nomor_draft         TEXT                  UNIQUE NOT NULL,
  nomor_surat         TEXT,
  tanggal_surat       DATE,
  tujuan              TEXT                  NOT NULL,
  perihal             TEXT                  NOT NULL,
  bidang              bidang_enum           NOT NULL,
  kategori            kategori_arsip        NOT NULL DEFAULT 'Umum',
  sifat               sifat_surat           NOT NULL DEFAULT 'Biasa',
  status              status_surat_keluar   NOT NULL DEFAULT 'Draft',
  penandatangan       TEXT,
  tembusan            TEXT[],
  keterangan          TEXT,
  file_url            TEXT,
  file_draft_url      TEXT,
  file_final_url      TEXT,
  unit_pengelola      UUID                  REFERENCES public.profiles(id),
  catatan_verifikasi  TEXT,
  diverifikasi_oleh   UUID                  REFERENCES public.profiles(id),
  tanggal_verifikasi  TIMESTAMPTZ,
  diberi_nomor_oleh   UUID                  REFERENCES public.profiles(id),
  tanggal_penomoran   TIMESTAMPTZ,
  is_rahasia          BOOLEAN               NOT NULL DEFAULT FALSE,
  is_deleted          BOOLEAN               NOT NULL DEFAULT FALSE,
  created_by          UUID                  REFERENCES public.profiles(id),
  updated_by          UUID                  REFERENCES public.profiles(id),
  created_at          TIMESTAMPTZ           NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ           NOT NULL DEFAULT NOW()
);

DROP TRIGGER IF EXISTS surat_keluar_updated_at ON public.surat_keluar;
CREATE TRIGGER surat_keluar_updated_at
  BEFORE UPDATE ON public.surat_keluar
  FOR EACH ROW EXECUTE PROCEDURE public.set_updated_at();

CREATE INDEX IF NOT EXISTS idx_sk_bidang  ON public.surat_keluar(bidang);
CREATE INDEX IF NOT EXISTS idx_sk_status  ON public.surat_keluar(status);
CREATE INDEX IF NOT EXISTS idx_sk_deleted ON public.surat_keluar(is_deleted);


-- ================================================================
-- BLOK 7: TABEL arsip
-- ================================================================

CREATE TABLE IF NOT EXISTS public.arsip (
  id                UUID              PRIMARY KEY DEFAULT uuid_generate_v4(),
  kode_arsip        TEXT              NOT NULL,
  perihal           TEXT              NOT NULL,
  tahun_arsip       SMALLINT          NOT NULL,
  bidang            bidang_enum       NOT NULL,
  kategori          kategori_arsip    NOT NULL DEFAULT 'Umum',
  jenis             jenis_arsip       NOT NULL DEFAULT 'Arsip Aktif',
  status            status_arsip      NOT NULL DEFAULT 'Aktif',
  lokasi_rak        TEXT,
  lokasi_box        TEXT,
  lokasi_laci       TEXT,
  retensi_aktif     SMALLINT,
  retensi_inaktif   SMALLINT,
  retensi_is_permanen BOOLEAN         DEFAULT FALSE,
  nasib_akhir       TEXT,
  deskripsi         TEXT,
  file_url          TEXT,
  file_urls         TEXT[],
  surat_masuk_id    UUID              REFERENCES public.surat_masuk(id),
  surat_keluar_id   UUID              REFERENCES public.surat_keluar(id),
  tanggal_inaktif   DATE,
  diserahkan_oleh   UUID              REFERENCES public.profiles(id),
  diterima_oleh     UUID              REFERENCES public.profiles(id),
  is_deleted        BOOLEAN           NOT NULL DEFAULT FALSE,
  deleted_at        TIMESTAMPTZ,
  created_by        UUID              REFERENCES public.profiles(id),
  updated_by        UUID              REFERENCES public.profiles(id),
  created_at        TIMESTAMPTZ       NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ       NOT NULL DEFAULT NOW()
);

DROP TRIGGER IF EXISTS arsip_updated_at ON public.arsip;
CREATE TRIGGER arsip_updated_at
  BEFORE UPDATE ON public.arsip
  FOR EACH ROW EXECUTE PROCEDURE public.set_updated_at();

CREATE INDEX IF NOT EXISTS idx_arsip_bidang  ON public.arsip(bidang);
CREATE INDEX IF NOT EXISTS idx_arsip_status  ON public.arsip(status);
CREATE INDEX IF NOT EXISTS idx_arsip_tahun   ON public.arsip(tahun_arsip);
CREATE INDEX IF NOT EXISTS idx_arsip_kode    ON public.arsip(kode_arsip);
CREATE INDEX IF NOT EXISTS idx_arsip_deleted ON public.arsip(is_deleted);


-- ================================================================
-- BLOK 8: TABEL peminjaman_arsip
-- ================================================================

CREATE TABLE IF NOT EXISTS public.peminjaman_arsip (
  id                        UUID          PRIMARY KEY DEFAULT uuid_generate_v4(),
  nomor_formulir            TEXT          UNIQUE NOT NULL,
  arsip_id                  UUID          NOT NULL REFERENCES public.arsip(id),
  peminjam_id               UUID          REFERENCES public.profiles(id),
  nama_peminjam             TEXT          NOT NULL,
  jabatan_peminjam          TEXT,
  nip_peminjam              TEXT,
  unit_peminjam             TEXT,
  instansi_peminjam         TEXT,
  keperluan                 TEXT          NOT NULL,
  tanggal_pinjam            DATE          NOT NULL DEFAULT CURRENT_DATE,
  tanggal_kembali_rencana   DATE          NOT NULL,
  tanggal_kembali_aktual    DATE,
  status                    status_pinjam NOT NULL DEFAULT 'Dipinjam',
  catatan                   TEXT,
  disetujui_oleh            UUID          REFERENCES public.profiles(id),
  dikembalikan_oleh         UUID          REFERENCES public.profiles(id),
  dilayani_oleh             UUID          REFERENCES public.profiles(id),
  created_by                UUID          REFERENCES public.profiles(id),
  created_at                TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  updated_at                TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

DROP TRIGGER IF EXISTS peminjaman_updated_at ON public.peminjaman_arsip;
CREATE TRIGGER peminjaman_updated_at
  BEFORE UPDATE ON public.peminjaman_arsip
  FOR EACH ROW EXECUTE PROCEDURE public.set_updated_at();

CREATE INDEX IF NOT EXISTS idx_pinjam_arsip  ON public.peminjaman_arsip(arsip_id);
CREATE INDEX IF NOT EXISTS idx_pinjam_status ON public.peminjaman_arsip(status);
CREATE INDEX IF NOT EXISTS idx_pinjam_tgl    ON public.peminjaman_arsip(tanggal_pinjam);


-- ================================================================
-- BLOK 9: TABEL penyusutan_arsip
-- ================================================================

CREATE TABLE IF NOT EXISTS public.penyusutan_arsip (
  id                    UUID                    PRIMARY KEY DEFAULT uuid_generate_v4(),
  arsip_id              UUID                    NOT NULL REFERENCES public.arsip(id),
  jenis_penyusutan      jenis_penyusutan_enum   NOT NULL,
  tanggal_usul          DATE                    NOT NULL DEFAULT CURRENT_DATE,
  tanggal_persetujuan   DATE,
  tanggal_pelaksanaan   DATE,
  status                status_musna            NOT NULL DEFAULT 'Menunggu',
  keterangan            TEXT,
  dasar_hukum           TEXT,
  berita_acara_url      TEXT,
  diusulkan_oleh        UUID                    NOT NULL REFERENCES public.profiles(id),
  disetujui_oleh        UUID                    REFERENCES public.profiles(id),
  created_at            TIMESTAMPTZ             NOT NULL DEFAULT NOW(),
  updated_at            TIMESTAMPTZ             NOT NULL DEFAULT NOW()
);

DROP TRIGGER IF EXISTS penyusutan_updated_at ON public.penyusutan_arsip;
CREATE TRIGGER penyusutan_updated_at
  BEFORE UPDATE ON public.penyusutan_arsip
  FOR EACH ROW EXECUTE PROCEDURE public.set_updated_at();

CREATE INDEX IF NOT EXISTS idx_susut_arsip  ON public.penyusutan_arsip(arsip_id);
CREATE INDEX IF NOT EXISTS idx_susut_jenis  ON public.penyusutan_arsip(jenis_penyusutan);
CREATE INDEX IF NOT EXISTS idx_susut_status ON public.penyusutan_arsip(status);


-- ================================================================
-- BLOK 10: TABEL regulasi
-- ================================================================

CREATE TABLE IF NOT EXISTS public.regulasi (
  id          UUID                  PRIMARY KEY DEFAULT uuid_generate_v4(),
  kode        TEXT,
  judul       TEXT                  NOT NULL,
  nomor       TEXT,
  tahun       SMALLINT,
  jenis       jenis_regulasi_enum,
  instansi    TEXT,
  tentang     TEXT,
  ringkasan   TEXT,
  file_url    TEXT,
  link_url    TEXT,
  is_active   BOOLEAN               NOT NULL DEFAULT TRUE,
  urutan      SMALLINT              DEFAULT 0,
  created_by  UUID                  REFERENCES public.profiles(id),
  created_at  TIMESTAMPTZ           NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ           NOT NULL DEFAULT NOW()
);

DROP TRIGGER IF EXISTS regulasi_updated_at ON public.regulasi;
CREATE TRIGGER regulasi_updated_at
  BEFORE UPDATE ON public.regulasi
  FOR EACH ROW EXECUTE PROCEDURE public.set_updated_at();

CREATE INDEX IF NOT EXISTS idx_reg_jenis ON public.regulasi(jenis);
CREATE INDEX IF NOT EXISTS idx_reg_tahun ON public.regulasi(tahun);


-- ================================================================
-- BLOK 11: VIEWS DASHBOARD
-- ================================================================

CREATE OR REPLACE VIEW public.v_statistik_surat_masuk AS
SELECT
  bidang,
  EXTRACT(YEAR  FROM tanggal_terima)::INTEGER AS tahun,
  EXTRACT(MONTH FROM tanggal_terima)::INTEGER AS bulan,
  COUNT(*) AS jumlah
FROM public.surat_masuk
WHERE is_deleted = FALSE
GROUP BY bidang, tahun, bulan
ORDER BY tahun DESC, bulan DESC;

CREATE OR REPLACE VIEW public.v_statistik_surat_keluar AS
SELECT
  bidang,
  EXTRACT(YEAR  FROM COALESCE(tanggal_surat, created_at::DATE))::INTEGER AS tahun,
  EXTRACT(MONTH FROM COALESCE(tanggal_surat, created_at::DATE))::INTEGER AS bulan,
  COUNT(*) AS jumlah
FROM public.surat_keluar
WHERE is_deleted = FALSE
GROUP BY bidang, tahun, bulan
ORDER BY tahun DESC, bulan DESC;

CREATE OR REPLACE VIEW public.v_statistik_arsip AS
SELECT
  bidang,
  status,
  jenis,
  COUNT(*) AS jumlah
FROM public.arsip
WHERE is_deleted = FALSE
GROUP BY bidang, status, jenis;

CREATE OR REPLACE VIEW public.v_peminjaman_aktif AS
SELECT
  p.id,
  p.nomor_formulir,
  p.nama_peminjam,
  p.jabatan_peminjam,
  p.unit_peminjam,
  p.keperluan,
  p.tanggal_pinjam,
  p.tanggal_kembali_rencana,
  p.status,
  a.perihal     AS judul_arsip,
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
     AND is_deleted = FALSE)                              AS surat_masuk_tahun_ini,
  (SELECT COUNT(*) FROM public.surat_keluar
   WHERE EXTRACT(YEAR FROM created_at) = EXTRACT(YEAR FROM NOW())
     AND is_deleted = FALSE)                              AS surat_keluar_tahun_ini,
  (SELECT COUNT(*) FROM public.arsip
   WHERE status = 'Aktif' AND is_deleted = FALSE)         AS arsip_aktif,
  (SELECT COUNT(*) FROM public.arsip
   WHERE status = 'Inaktif' AND is_deleted = FALSE)       AS arsip_inaktif,
  (SELECT COUNT(*) FROM public.peminjaman_arsip
   WHERE status = 'Dipinjam')                             AS peminjaman_aktif,
  (SELECT COUNT(*) FROM public.penyusutan_arsip
   WHERE status = 'Menunggu')                             AS penyusutan_pending;


-- ================================================================
-- BLOK 12: GRANT PERMISSIONS
-- ================================================================

GRANT SELECT, INSERT, UPDATE ON public.profiles          TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.surat_masuk       TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.surat_keluar      TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.arsip             TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.peminjaman_arsip  TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.penyusutan_arsip  TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.regulasi          TO authenticated;

GRANT SELECT ON public.v_statistik_surat_masuk   TO authenticated;
GRANT SELECT ON public.v_statistik_surat_keluar  TO authenticated;
GRANT SELECT ON public.v_statistik_arsip          TO authenticated;
GRANT SELECT ON public.v_peminjaman_aktif         TO authenticated;
GRANT SELECT ON public.v_dashboard_summary        TO authenticated;

-- anon hanya bisa baca regulasi aktif (untuk halaman publik jika ada)
GRANT SELECT ON public.regulasi TO anon;

-- ================================================================
-- SELESAI — Lanjutkan dengan 02_rls_final.sql
-- ================================================================
