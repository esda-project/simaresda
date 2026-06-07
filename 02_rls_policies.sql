-- ============================================================
-- SIMARESDA - Row Level Security (RLS) Policies
-- Role: Admin > Pengelola > TU
-- ============================================================

-- ============================================================
-- HELPER FUNCTIONS
-- ============================================================

-- Ambil role user yang sedang login
CREATE OR REPLACE FUNCTION auth.user_role()
RETURNS role_user AS $$
  SELECT role FROM public.profiles WHERE id = auth.uid();
$$ LANGUAGE sql STABLE SECURITY DEFINER;

-- Cek apakah user adalah Admin
CREATE OR REPLACE FUNCTION auth.is_admin()
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'Admin' AND is_active = TRUE
  );
$$ LANGUAGE sql STABLE SECURITY DEFINER;

-- Cek apakah user adalah Admin atau Pengelola
CREATE OR REPLACE FUNCTION auth.is_pengelola_or_admin()
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role IN ('Admin', 'Pengelola') AND is_active = TRUE
  );
$$ LANGUAGE sql STABLE SECURITY DEFINER;

-- Cek apakah user aktif
CREATE OR REPLACE FUNCTION auth.is_active_user()
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND is_active = TRUE
  );
$$ LANGUAGE sql STABLE SECURITY DEFINER;

-- ============================================================
-- ENABLE RLS ON ALL TABLES
-- ============================================================

ALTER TABLE public.profiles           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.surat_masuk        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.surat_keluar       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.arsip              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.peminjaman_arsip   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pemusnahan_arsip   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_trail        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.regulasi           ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- POLICIES: profiles
-- ============================================================

-- Semua user aktif bisa lihat profil sendiri
CREATE POLICY "profiles: user bisa baca profil sendiri"
  ON public.profiles FOR SELECT
  USING (id = auth.uid() AND is_active = TRUE);

-- Admin bisa lihat semua profil
CREATE POLICY "profiles: admin bisa baca semua"
  ON public.profiles FOR SELECT
  USING (auth.is_admin());

-- User hanya bisa update profil sendiri (bukan role)
CREATE POLICY "profiles: user update profil sendiri"
  ON public.profiles FOR UPDATE
  USING (id = auth.uid())
  WITH CHECK (
    id = auth.uid() AND
    role = (SELECT role FROM public.profiles WHERE id = auth.uid())  -- role tidak boleh diubah sendiri
  );

-- Hanya Admin yang bisa create / update role user
CREATE POLICY "profiles: admin manage semua"
  ON public.profiles FOR ALL
  USING (auth.is_admin());

-- ============================================================
-- POLICIES: surat_masuk
-- ============================================================

-- Semua user aktif bisa SELECT surat masuk yang tidak dihapus
CREATE POLICY "surat_masuk: semua user bisa baca"
  ON public.surat_masuk FOR SELECT
  USING (is_deleted = FALSE AND auth.is_active_user());

-- TU dan Pengelola dan Admin bisa INSERT
CREATE POLICY "surat_masuk: user aktif bisa tambah"
  ON public.surat_masuk FOR INSERT
  WITH CHECK (auth.is_active_user() AND created_by = auth.uid());

-- Pengelola + Admin bisa UPDATE
CREATE POLICY "surat_masuk: pengelola dan admin bisa edit"
  ON public.surat_masuk FOR UPDATE
  USING (auth.is_pengelola_or_admin())
  WITH CHECK (auth.is_pengelola_or_admin());

-- TU bisa update surat yang dia buat sendiri, dalam 24 jam
CREATE POLICY "surat_masuk: TU edit milik sendiri (24 jam)"
  ON public.surat_masuk FOR UPDATE
  USING (
    created_by = auth.uid() AND
    created_at > NOW() - INTERVAL '24 hours' AND
    auth.user_role() = 'TU'
  );

-- Hanya Admin bisa DELETE (soft delete via is_deleted)
CREATE POLICY "surat_masuk: hanya admin bisa hapus"
  ON public.surat_masuk FOR DELETE
  USING (auth.is_admin());

-- ============================================================
-- POLICIES: surat_keluar
-- ============================================================

CREATE POLICY "surat_keluar: semua user aktif bisa baca"
  ON public.surat_keluar FOR SELECT
  USING (is_deleted = FALSE AND auth.is_active_user());

CREATE POLICY "surat_keluar: user aktif bisa tambah"
  ON public.surat_keluar FOR INSERT
  WITH CHECK (auth.is_active_user() AND created_by = auth.uid());

CREATE POLICY "surat_keluar: pengelola dan admin bisa edit"
  ON public.surat_keluar FOR UPDATE
  USING (auth.is_pengelola_or_admin());

CREATE POLICY "surat_keluar: hanya admin bisa hapus"
  ON public.surat_keluar FOR DELETE
  USING (auth.is_admin());

-- ============================================================
-- POLICIES: arsip
-- ============================================================

-- Semua user aktif bisa lihat arsip non-rahasia
CREATE POLICY "arsip: semua user baca arsip non-rahasia"
  ON public.arsip FOR SELECT
  USING (
    is_deleted = FALSE AND
    auth.is_active_user() AND
    kategori != 'Rahasia'
  );

-- Pengelola dan Admin bisa lihat arsip rahasia juga
CREATE POLICY "arsip: pengelola dan admin baca arsip rahasia"
  ON public.arsip FOR SELECT
  USING (
    is_deleted = FALSE AND
    auth.is_pengelola_or_admin()
  );

-- Pengelola dan Admin bisa tambah arsip
CREATE POLICY "arsip: pengelola dan admin bisa tambah"
  ON public.arsip FOR INSERT
  WITH CHECK (auth.is_pengelola_or_admin() AND created_by = auth.uid());

-- Pengelola dan Admin bisa update arsip
CREATE POLICY "arsip: pengelola dan admin bisa edit"
  ON public.arsip FOR UPDATE
  USING (auth.is_pengelola_or_admin());

-- Hanya Admin yang bisa soft delete (is_deleted = true)
CREATE POLICY "arsip: hanya admin bisa hapus"
  ON public.arsip FOR DELETE
  USING (auth.is_admin());

-- ============================================================
-- POLICIES: peminjaman_arsip
-- ============================================================

-- Semua user aktif bisa baca peminjaman
CREATE POLICY "pinjam: semua user aktif bisa baca"
  ON public.peminjaman_arsip FOR SELECT
  USING (auth.is_active_user());

-- Semua user aktif bisa buat peminjaman
CREATE POLICY "pinjam: semua user bisa buat formulir"
  ON public.peminjaman_arsip FOR INSERT
  WITH CHECK (auth.is_active_user() AND created_by = auth.uid());

-- Pengelola dan Admin bisa update (proses kembali, ubah status)
CREATE POLICY "pinjam: pengelola dan admin bisa update"
  ON public.peminjaman_arsip FOR UPDATE
  USING (auth.is_pengelola_or_admin());

-- TU hanya bisa update peminjaman yang dia buat, selama belum disetujui
CREATE POLICY "pinjam: TU update milik sendiri jika belum diproses"
  ON public.peminjaman_arsip FOR UPDATE
  USING (
    created_by = auth.uid() AND
    status = 'Dipinjam' AND
    auth.user_role() = 'TU'
  );

-- ============================================================
-- POLICIES: pemusnahan_arsip
-- ============================================================

-- Semua user aktif bisa baca pengajuan pemusnahan
CREATE POLICY "musna: semua user baca"
  ON public.pemusnahan_arsip FOR SELECT
  USING (auth.is_active_user());

-- Pengelola dan Admin bisa ajukan pemusnahan
CREATE POLICY "musna: pengelola dan admin bisa ajukan"
  ON public.pemusnahan_arsip FOR INSERT
  WITH CHECK (auth.is_pengelola_or_admin() AND diajukan_oleh = auth.uid());

-- Hanya Admin yang bisa setujui / tolak pemusnahan
CREATE POLICY "musna: hanya admin bisa setujui"
  ON public.pemusnahan_arsip FOR UPDATE
  USING (auth.is_admin());

-- ============================================================
-- POLICIES: audit_trail
-- ============================================================

-- Semua user aktif bisa INSERT log (dari server/trigger)
CREATE POLICY "audit: semua bisa insert"
  ON public.audit_trail FOR INSERT
  WITH CHECK (TRUE);

-- Admin bisa baca semua log
CREATE POLICY "audit: admin bisa baca semua"
  ON public.audit_trail FOR SELECT
  USING (auth.is_admin());

-- Pengelola bisa baca log aktivitas sendiri
CREATE POLICY "audit: pengelola baca log sendiri"
  ON public.audit_trail FOR SELECT
  USING (user_id = auth.uid() AND auth.is_pengelola_or_admin());

-- Tidak ada yang bisa UPDATE atau DELETE audit trail
-- (immutable log — tidak perlu policy UPDATE/DELETE)

-- ============================================================
-- POLICIES: regulasi
-- ============================================================

-- Semua user bisa baca regulasi yang aktif
CREATE POLICY "regulasi: semua bisa baca"
  ON public.regulasi FOR SELECT
  USING (is_active = TRUE AND auth.is_active_user());

-- Hanya Admin yang bisa kelola regulasi (CMS)
CREATE POLICY "regulasi: admin kelola"
  ON public.regulasi FOR ALL
  USING (auth.is_admin());

-- ============================================================
-- GRANT PERMISSIONS TO authenticated role
-- ============================================================

GRANT USAGE ON SCHEMA public TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.profiles TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.surat_masuk TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.surat_keluar TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.arsip TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.peminjaman_arsip TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.pemusnahan_arsip TO authenticated;
GRANT SELECT, INSERT ON public.audit_trail TO authenticated;
GRANT SELECT ON public.regulasi TO authenticated;
GRANT INSERT, UPDATE, DELETE ON public.regulasi TO authenticated;

-- Grant sequence usage
GRANT USAGE ON SEQUENCE seq_surat_masuk TO authenticated;
GRANT USAGE ON SEQUENCE seq_surat_keluar TO authenticated;
GRANT USAGE ON SEQUENCE seq_arsip TO authenticated;
GRANT USAGE ON SEQUENCE seq_peminjaman TO authenticated;
GRANT USAGE ON SEQUENCE public.audit_trail_id_seq TO authenticated;
