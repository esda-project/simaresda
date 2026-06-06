-- ============================================================
-- SIMARESDA - Sistem Manajemen Arsip Daerah
-- SQL Schema untuk Supabase PostgreSQL
-- Periode Tahun Anggaran 2025–2030
-- ============================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================
-- ENUM TYPES
-- ============================================================

CREATE TYPE role_user AS ENUM ('Admin', 'Pengelola', 'TU');
CREATE TYPE status_surat_masuk AS ENUM ('Disposisi', 'Diproses', 'Selesai', 'Arsip');
CREATE TYPE status_surat_keluar AS ENUM ('Draft', 'Terkirim', 'Dibatalkan');
CREATE TYPE kategori_arsip AS ENUM ('Umum', 'Keuangan', 'Kepegawaian', 'Teknis', 'Rahasia');
CREATE TYPE sifat_surat AS ENUM ('Biasa', 'Penting', 'Segera', 'Rahasia');
CREATE TYPE status_arsip AS ENUM ('Aktif', 'Inaktif', 'Dipindah', 'Dimusnahkan');
CREATE TYPE status_pinjam AS ENUM ('Dipinjam', 'Dikembalikan', 'Terlambat');
CREATE TYPE status_musna AS ENUM ('Menunggu', 'Disetujui', 'Ditolak', 'Selesai');
CREATE TYPE jenis_arsip AS ENUM ('Arsip Aktif', 'Arsip Inaktif');
CREATE TYPE jenis_audit AS ENUM ('LOGIN','LOGOUT','CREATE','READ','UPDATE','DELETE','DELETE (SOFT)','VIEW','PRINT','EXPORT');

-- ============================================================
-- TABLE: profiles (extends auth.users)
-- ============================================================

CREATE TABLE public.profiles (
  id            UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  nama_lengkap  TEXT NOT NULL,
  jabatan       TEXT,
  nip           TEXT UNIQUE,
  role          role_user NOT NULL DEFAULT 'TU',
  unit_kerja    TEXT,
  is_active     BOOLEAN NOT NULL DEFAULT TRUE,
  avatar_url    TEXT,
  last_login    TIMESTAMPTZ,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE public.profiles IS 'Profil pengguna sistem, terhubung ke auth.users';

-- ============================================================
-- TABLE: surat_masuk
-- ============================================================

CREATE TABLE public.surat_masuk (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nomor_agenda  TEXT UNIQUE NOT NULL,  -- SM-{YYYY}-{SEQ}
  nomor_surat   TEXT NOT NULL,
  tanggal_surat DATE NOT NULL,
  tanggal_terima DATE NOT NULL DEFAULT CURRENT_DATE,
  asal_surat    TEXT NOT NULL,
  perihal       TEXT NOT NULL,
  kategori      kategori_arsip NOT NULL DEFAULT 'Umum',
  sifat         sifat_surat NOT NULL DEFAULT 'Biasa',
  status        status_surat_masuk NOT NULL DEFAULT 'Disposisi',
  keterangan    TEXT,
  file_url      TEXT,                  -- path ke Supabase Storage
  disposisi_ke  UUID REFERENCES public.profiles(id),
  created_by    UUID NOT NULL REFERENCES public.profiles(id),
  updated_by    UUID REFERENCES public.profiles(id),
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  is_deleted    BOOLEAN NOT NULL DEFAULT FALSE
);

COMMENT ON TABLE public.surat_masuk IS 'Arsip surat masuk sesuai standar tata kearsipan';
CREATE INDEX idx_surat_masuk_status ON public.surat_masuk(status);
CREATE INDEX idx_surat_masuk_tanggal ON public.surat_masuk(tanggal_terima DESC);
CREATE INDEX idx_surat_masuk_deleted ON public.surat_masuk(is_deleted);

-- ============================================================
-- TABLE: surat_keluar
-- ============================================================

CREATE TABLE public.surat_keluar (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nomor_agenda    TEXT UNIQUE NOT NULL,  -- SK-{YYYY}-{SEQ}
  nomor_surat     TEXT UNIQUE NOT NULL,  -- auto-generate: {SEQ}/{KODE}/{BLN}/{YYYY}
  tanggal_surat   DATE NOT NULL DEFAULT CURRENT_DATE,
  tujuan          TEXT NOT NULL,
  perihal         TEXT NOT NULL,
  kategori        kategori_arsip NOT NULL DEFAULT 'Umum',
  sifat           sifat_surat NOT NULL DEFAULT 'Biasa',
  status          status_surat_keluar NOT NULL DEFAULT 'Draft',
  penandatangan   TEXT,
  tembusan        TEXT[],               -- array instansi tembusan
  keterangan      TEXT,
  file_url        TEXT,
  created_by      UUID NOT NULL REFERENCES public.profiles(id),
  updated_by      UUID REFERENCES public.profiles(id),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  is_deleted      BOOLEAN NOT NULL DEFAULT FALSE
);

COMMENT ON TABLE public.surat_keluar IS 'Arsip surat keluar dengan auto-generate nomor surat';
CREATE INDEX idx_surat_keluar_status ON public.surat_keluar(status);
CREATE INDEX idx_surat_keluar_tanggal ON public.surat_keluar(tanggal_surat DESC);

-- ============================================================
-- TABLE: arsip (penyimpanan)
-- ============================================================

CREATE TABLE public.arsip (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  kode_arsip      TEXT UNIQUE NOT NULL,  -- ARK-{YYYY}-{SEQ}
  perihal         TEXT NOT NULL,
  tahun_arsip     SMALLINT NOT NULL,
  kategori        kategori_arsip NOT NULL DEFAULT 'Umum',
  status          status_arsip NOT NULL DEFAULT 'Aktif',
  jenis           jenis_arsip NOT NULL DEFAULT 'Arsip Aktif',
  lokasi_rak      TEXT,
  lokasi_box      TEXT,
  lokasi_laci     TEXT,
  retensi_aktif   SMALLINT,             -- tahun retensi aktif
  retensi_inaktif SMALLINT,             -- tahun retensi inaktif
  retensi_is_permanen BOOLEAN DEFAULT FALSE,
  nasib_akhir     TEXT DEFAULT 'Musnah', -- Musnah / Permanen
  deskripsi       TEXT,
  file_url        TEXT,
  surat_masuk_id  UUID REFERENCES public.surat_masuk(id),
  surat_keluar_id UUID REFERENCES public.surat_keluar(id),
  created_by      UUID NOT NULL REFERENCES public.profiles(id),
  updated_by      UUID REFERENCES public.profiles(id),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at      TIMESTAMPTZ,
  is_deleted      BOOLEAN NOT NULL DEFAULT FALSE
);

COMMENT ON TABLE public.arsip IS 'Penyimpanan arsip aktif dan inaktif';
CREATE INDEX idx_arsip_status ON public.arsip(status);
CREATE INDEX idx_arsip_kategori ON public.arsip(kategori);
CREATE INDEX idx_arsip_tahun ON public.arsip(tahun_arsip DESC);
CREATE INDEX idx_arsip_deleted ON public.arsip(is_deleted);

-- ============================================================
-- TABLE: peminjaman_arsip
-- ============================================================

CREATE TABLE public.peminjaman_arsip (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nomor_formulir  TEXT UNIQUE NOT NULL,  -- FP-{YYYY}-{SEQ}
  arsip_id        UUID NOT NULL REFERENCES public.arsip(id),
  nama_peminjam   TEXT NOT NULL,
  jabatan_peminjam TEXT NOT NULL,
  nip_peminjam    TEXT,
  unit_peminjam   TEXT,
  keperluan       TEXT,
  tanggal_pinjam  DATE NOT NULL DEFAULT CURRENT_DATE,
  tanggal_kembali_rencana DATE NOT NULL,
  tanggal_kembali_aktual  DATE,
  status          status_pinjam NOT NULL DEFAULT 'Dipinjam',
  disetujui_oleh  UUID REFERENCES public.profiles(id),
  dikembalikan_oleh UUID REFERENCES public.profiles(id),
  catatan         TEXT,
  created_by      UUID NOT NULL REFERENCES public.profiles(id),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE public.peminjaman_arsip IS 'Form peminjaman arsip aktif dan inaktif';
CREATE INDEX idx_pinjam_status ON public.peminjaman_arsip(status);
CREATE INDEX idx_pinjam_arsip ON public.peminjaman_arsip(arsip_id);
CREATE INDEX idx_pinjam_tgl_kembali ON public.peminjaman_arsip(tanggal_kembali_rencana);

-- ============================================================
-- TABLE: pemusnahan_arsip
-- ============================================================

CREATE TABLE public.pemusnahan_arsip (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  arsip_id        UUID NOT NULL REFERENCES public.arsip(id),
  nomor_ba        TEXT,                 -- Nomor Berita Acara
  alasan          TEXT NOT NULL,
  metode          TEXT DEFAULT 'Pencacahan',  -- Pencacahan / Pembakaran / dll
  status          status_musna NOT NULL DEFAULT 'Menunggu',
  diajukan_oleh   UUID NOT NULL REFERENCES public.profiles(id),
  disetujui_oleh  UUID REFERENCES public.profiles(id),
  tanggal_ajuan   DATE NOT NULL DEFAULT CURRENT_DATE,
  tanggal_persetujuan DATE,
  tanggal_pelaksanaan DATE,
  catatan         TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE public.pemusnahan_arsip IS 'Log pemusnahan arsip dengan soft delete dan audit trail';
CREATE INDEX idx_musna_status ON public.pemusnahan_arsip(status);

-- ============================================================
-- TABLE: audit_trail
-- ============================================================

CREATE TABLE public.audit_trail (
  id          BIGSERIAL PRIMARY KEY,
  user_id     UUID REFERENCES public.profiles(id),
  user_name   TEXT NOT NULL,
  user_role   role_user NOT NULL,
  aksi        jenis_audit NOT NULL,
  tabel       TEXT,
  record_id   TEXT,
  data_lama   JSONB,
  data_baru   JSONB,
  ip_address  INET,
  user_agent  TEXT,
  keterangan  TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE public.audit_trail IS 'Log semua aktivitas sistem untuk compliance kearsipan';
CREATE INDEX idx_audit_user ON public.audit_trail(user_id);
CREATE INDEX idx_audit_aksi ON public.audit_trail(aksi);
CREATE INDEX idx_audit_created ON public.audit_trail(created_at DESC);
CREATE INDEX idx_audit_tabel ON public.audit_trail(tabel, record_id);

-- ============================================================
-- TABLE: regulasi (CMS sederhana)
-- ============================================================

CREATE TABLE public.regulasi (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  kode        TEXT NOT NULL,            -- UU, PP, ANRI, SE, PERDA
  judul       TEXT NOT NULL,
  nomor       TEXT,                     -- Nomor peraturan
  tahun       SMALLINT,
  instansi    TEXT,
  ringkasan   TEXT,
  file_url    TEXT,
  link_url    TEXT,
  is_active   BOOLEAN NOT NULL DEFAULT TRUE,
  urutan      SMALLINT DEFAULT 0,
  created_by  UUID REFERENCES public.profiles(id),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE public.regulasi IS 'Repository regulasi dan peraturan kearsipan (CMS)';

-- ============================================================
-- AUTO-INCREMENT SEQUENCES (untuk nomor surat baku)
-- ============================================================

CREATE SEQUENCE seq_surat_masuk START 1;
CREATE SEQUENCE seq_surat_keluar START 1;
CREATE SEQUENCE seq_arsip START 1;
CREATE SEQUENCE seq_peminjaman START 1;

-- ============================================================
-- FUNCTIONS: Auto-generate nomor surat
-- ============================================================

CREATE OR REPLACE FUNCTION generate_nomor_agenda_masuk()
RETURNS TEXT AS $$
DECLARE
  tahun TEXT := TO_CHAR(NOW(), 'YYYY');
  seq   TEXT := LPAD(NEXTVAL('seq_surat_masuk')::TEXT, 3, '0');
BEGIN
  RETURN 'SM-' || tahun || '-' || seq;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION generate_nomor_agenda_keluar()
RETURNS TEXT AS $$
DECLARE
  tahun TEXT := TO_CHAR(NOW(), 'YYYY');
  seq   TEXT := LPAD(NEXTVAL('seq_surat_keluar')::TEXT, 3, '0');
BEGIN
  RETURN 'SK-' || tahun || '-' || seq;
END;
$$ LANGUAGE plpgsql;

-- Format baku nomor surat keluar: {SEQ}/{KODE_UNIT}/{BLN_ROMAWI}/{YYYY}
CREATE OR REPLACE FUNCTION generate_nomor_surat_keluar(kode_unit TEXT DEFAULT 'ORG')
RETURNS TEXT AS $$
DECLARE
  seq       INT := CURRVAL('seq_surat_keluar');
  bulan_rom TEXT[] := ARRAY['I','II','III','IV','V','VI','VII','VIII','IX','X','XI','XII'];
  bln       TEXT := bulan_rom[EXTRACT(MONTH FROM NOW())::INT];
  thn       TEXT := TO_CHAR(NOW(), 'YYYY');
BEGIN
  RETURN seq || '/' || kode_unit || '/' || bln || '/' || thn;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION generate_kode_arsip()
RETURNS TEXT AS $$
DECLARE
  tahun TEXT := TO_CHAR(NOW(), 'YYYY');
  seq   TEXT := LPAD(NEXTVAL('seq_arsip')::TEXT, 3, '0');
BEGIN
  RETURN 'ARK-' || tahun || '-' || seq;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION generate_nomor_formulir_pinjam()
RETURNS TEXT AS $$
DECLARE
  tahun TEXT := TO_CHAR(NOW(), 'YYYY');
  seq   TEXT := LPAD(NEXTVAL('seq_peminjaman')::TEXT, 3, '0');
BEGIN
  RETURN 'FP-' || tahun || '-' || seq;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- FUNCTION: updated_at trigger
-- ============================================================

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at trigger to all tables
CREATE TRIGGER trg_profiles_updated_at BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_surat_masuk_updated_at BEFORE UPDATE ON public.surat_masuk FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_surat_keluar_updated_at BEFORE UPDATE ON public.surat_keluar FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_arsip_updated_at BEFORE UPDATE ON public.arsip FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_pinjam_updated_at BEFORE UPDATE ON public.peminjaman_arsip FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_musna_updated_at BEFORE UPDATE ON public.pemusnahan_arsip FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_regulasi_updated_at BEFORE UPDATE ON public.regulasi FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ============================================================
-- FUNCTION: Soft delete arsip → trigger pemusnahan
-- ============================================================

CREATE OR REPLACE FUNCTION soft_delete_arsip()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.is_deleted = TRUE AND OLD.is_deleted = FALSE THEN
    NEW.deleted_at = NOW();
    NEW.status = 'Dimusnahkan';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_soft_delete_arsip
  BEFORE UPDATE ON public.arsip
  FOR EACH ROW EXECUTE FUNCTION soft_delete_arsip();

-- ============================================================
-- FUNCTION: Auto-update status peminjaman jika terlambat
-- ============================================================

CREATE OR REPLACE FUNCTION check_overdue_pinjam()
RETURNS void AS $$
BEGIN
  UPDATE public.peminjaman_arsip
  SET status = 'Terlambat', updated_at = NOW()
  WHERE status = 'Dipinjam'
    AND tanggal_kembali_rencana < CURRENT_DATE;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- FUNCTION: Auto-create profile saat user baru signup
-- ============================================================

CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, nama_lengkap, role)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'nama_lengkap', NEW.email),
    COALESCE((NEW.raw_user_meta_data->>'role')::role_user, 'TU')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- ============================================================
-- SEED DATA: Regulasi
-- ============================================================

INSERT INTO public.regulasi (kode, judul, nomor, tahun, instansi, urutan) VALUES
('UU',   'Undang-Undang tentang Kearsipan', '43', 2009, 'DPR RI', 1),
('PP',   'Pelaksanaan UU No. 43 Tahun 2009 tentang Kearsipan', '28', 2012, 'Presiden RI', 2),
('ANRI', 'Pedoman Penyusutan Arsip', '37', 2016, 'ANRI', 3),
('ANRI', 'Pembuatan dan Penggunaan Arsip', '9', 2018, 'ANRI', 4),
('ANRI', 'Pedoman Pengelolaan Arsip Aktif', '19', 2012, 'ANRI', 5),
('SE',   'Digitalisasi Arsip Pemerintah', '6', 2020, 'KemenPANRB', 6);
