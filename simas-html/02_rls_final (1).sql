-- ================================================================
-- SIMARESDA — RLS POLICY FINAL (v5)
-- Perbaikan: enum tanpa schema prefix "public."
-- Jalankan setelah 01_migration_final.sql
-- ================================================================


-- ================================================================
-- HELPER FUNCTIONS
-- ================================================================

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'Admin' AND is_active = TRUE
  );
$$;

CREATE OR REPLACE FUNCTION public.is_tu()
RETURNS BOOLEAN LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'TU' AND is_active = TRUE
  );
$$;

CREATE OR REPLACE FUNCTION public.is_pengelola()
RETURNS BOOLEAN LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'Pengelola' AND is_active = TRUE
  );
$$;

CREATE OR REPLACE FUNCTION public.is_kearsipan()
RETURNS BOOLEAN LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'Unit Kearsipan' AND is_active = TRUE
  );
$$;

CREATE OR REPLACE FUNCTION public.get_my_bidang()
RETURNS bidang_enum LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT bidang FROM public.profiles WHERE id = auth.uid() LIMIT 1;
$$;


-- ================================================================
-- TABLE: profiles
-- ================================================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "profiles_admin_all"    ON public.profiles;
DROP POLICY IF EXISTS "profiles_self_select"  ON public.profiles;
DROP POLICY IF EXISTS "profiles_self_update"  ON public.profiles;
DROP POLICY IF EXISTS "profiles_tu_ks_select" ON public.profiles;

CREATE POLICY "profiles_admin_all" ON public.profiles
  FOR ALL TO authenticated
  USING (public.is_admin()) WITH CHECK (public.is_admin());

CREATE POLICY "profiles_self_select" ON public.profiles
  FOR SELECT TO authenticated
  USING (id = auth.uid());

CREATE POLICY "profiles_self_update" ON public.profiles
  FOR UPDATE TO authenticated
  USING (id = auth.uid())
  WITH CHECK (
    id = auth.uid()
    AND role = (SELECT role FROM public.profiles WHERE id = auth.uid())
    AND is_active = TRUE
  );

-- TU & Unit Kearsipan: baca semua profil (untuk dropdown disposisi)
CREATE POLICY "profiles_tu_ks_select" ON public.profiles
  FOR SELECT TO authenticated
  USING (public.is_tu() OR public.is_kearsipan());


-- ================================================================
-- TABLE: surat_masuk
-- Kolom disposisi: "disposisi_ke" (bukan tujuan_disposisi)
-- ================================================================

ALTER TABLE public.surat_masuk ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "sm_admin_all"  ON public.surat_masuk;
DROP POLICY IF EXISTS "sm_tu_all"     ON public.surat_masuk;
DROP POLICY IF EXISTS "sm_up_select"  ON public.surat_masuk;
DROP POLICY IF EXISTS "sm_up_update"  ON public.surat_masuk;
DROP POLICY IF EXISTS "sm_ks_select"  ON public.surat_masuk;

CREATE POLICY "sm_admin_all" ON public.surat_masuk
  FOR ALL TO authenticated
  USING (public.is_admin()) WITH CHECK (public.is_admin());

CREATE POLICY "sm_tu_all" ON public.surat_masuk
  FOR ALL TO authenticated
  USING (public.is_tu()) WITH CHECK (public.is_tu());

CREATE POLICY "sm_up_select" ON public.surat_masuk
  FOR SELECT TO authenticated
  USING (
    public.is_pengelola()
    AND is_deleted = FALSE
    AND (
      disposisi_ke = auth.uid()
      OR bidang = public.get_my_bidang()
    )
  );

CREATE POLICY "sm_up_update" ON public.surat_masuk
  FOR UPDATE TO authenticated
  USING (
    public.is_pengelola()
    AND disposisi_ke = auth.uid()
  );

CREATE POLICY "sm_ks_select" ON public.surat_masuk
  FOR SELECT TO authenticated
  USING (public.is_kearsipan() AND is_deleted = FALSE);


-- ================================================================
-- TABLE: surat_keluar
-- status existing: 'Draft', 'Terkirim', 'Dibatalkan'
-- ================================================================

ALTER TABLE public.surat_keluar ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "sk_admin_all"  ON public.surat_keluar;
DROP POLICY IF EXISTS "sk_tu_all"     ON public.surat_keluar;
DROP POLICY IF EXISTS "sk_up_insert"  ON public.surat_keluar;
DROP POLICY IF EXISTS "sk_up_select"  ON public.surat_keluar;
DROP POLICY IF EXISTS "sk_up_update"  ON public.surat_keluar;
DROP POLICY IF EXISTS "sk_ks_select"  ON public.surat_keluar;

CREATE POLICY "sk_admin_all" ON public.surat_keluar
  FOR ALL TO authenticated
  USING (public.is_admin()) WITH CHECK (public.is_admin());

CREATE POLICY "sk_tu_all" ON public.surat_keluar
  FOR ALL TO authenticated
  USING (public.is_tu()) WITH CHECK (public.is_tu());

CREATE POLICY "sk_up_insert" ON public.surat_keluar
  FOR INSERT TO authenticated
  WITH CHECK (
    public.is_pengelola()
    AND bidang = public.get_my_bidang()
    AND created_by = auth.uid()
  );

CREATE POLICY "sk_up_select" ON public.surat_keluar
  FOR SELECT TO authenticated
  USING (
    public.is_pengelola()
    AND bidang = public.get_my_bidang()
    AND is_deleted = FALSE
  );

CREATE POLICY "sk_up_update" ON public.surat_keluar
  FOR UPDATE TO authenticated
  USING (
    public.is_pengelola()
    AND created_by = auth.uid()
    AND status = 'Draft'
  );

CREATE POLICY "sk_ks_select" ON public.surat_keluar
  FOR SELECT TO authenticated
  USING (public.is_kearsipan() AND is_deleted = FALSE);


-- ================================================================
-- TABLE: arsip
-- status: 'Aktif', 'Inaktif', 'Dipindah', 'Dimusnahkan'
-- ================================================================

ALTER TABLE public.arsip ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "arsip_admin_all"  ON public.arsip;
DROP POLICY IF EXISTS "arsip_tu_select"  ON public.arsip;
DROP POLICY IF EXISTS "arsip_up_select"  ON public.arsip;
DROP POLICY IF EXISTS "arsip_up_insert"  ON public.arsip;
DROP POLICY IF EXISTS "arsip_up_update"  ON public.arsip;
DROP POLICY IF EXISTS "arsip_ks_all"     ON public.arsip;

CREATE POLICY "arsip_admin_all" ON public.arsip
  FOR ALL TO authenticated
  USING (public.is_admin()) WITH CHECK (public.is_admin());

-- TU: baca semua arsip, tidak bisa hapus
CREATE POLICY "arsip_tu_select" ON public.arsip
  FOR SELECT TO authenticated
  USING (public.is_tu() AND is_deleted = FALSE);

-- Pengelola: CRUD arsip aktif bidangnya
CREATE POLICY "arsip_up_select" ON public.arsip
  FOR SELECT TO authenticated
  USING (
    public.is_pengelola()
    AND bidang = public.get_my_bidang()
    AND is_deleted = FALSE
  );

CREATE POLICY "arsip_up_insert" ON public.arsip
  FOR INSERT TO authenticated
  WITH CHECK (
    public.is_pengelola()
    AND bidang = public.get_my_bidang()
    AND status = 'Aktif'
    AND created_by = auth.uid()
  );

CREATE POLICY "arsip_up_update" ON public.arsip
  FOR UPDATE TO authenticated
  USING (
    public.is_pengelola()
    AND bidang = public.get_my_bidang()
    AND status = 'Aktif'
  );

-- Unit Kearsipan: full access semua arsip
CREATE POLICY "arsip_ks_all" ON public.arsip
  FOR ALL TO authenticated
  USING (public.is_kearsipan()) WITH CHECK (public.is_kearsipan());


-- ================================================================
-- TABLE: peminjaman_arsip
-- ================================================================

ALTER TABLE public.peminjaman_arsip ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "pinjam_admin_all"  ON public.peminjaman_arsip;
DROP POLICY IF EXISTS "pinjam_tu_select"  ON public.peminjaman_arsip;
DROP POLICY IF EXISTS "pinjam_up_select"  ON public.peminjaman_arsip;
DROP POLICY IF EXISTS "pinjam_up_insert"  ON public.peminjaman_arsip;
DROP POLICY IF EXISTS "pinjam_up_update"  ON public.peminjaman_arsip;
DROP POLICY IF EXISTS "pinjam_ks_all"     ON public.peminjaman_arsip;

CREATE POLICY "pinjam_admin_all" ON public.peminjaman_arsip
  FOR ALL TO authenticated
  USING (public.is_admin()) WITH CHECK (public.is_admin());

CREATE POLICY "pinjam_tu_select" ON public.peminjaman_arsip
  FOR SELECT TO authenticated
  USING (public.is_tu());

CREATE POLICY "pinjam_up_select" ON public.peminjaman_arsip
  FOR SELECT TO authenticated
  USING (
    public.is_pengelola()
    AND EXISTS (
      SELECT 1 FROM public.arsip a
      WHERE a.id = arsip_id
        AND a.bidang = public.get_my_bidang()
        AND a.status = 'Aktif'
        AND a.is_deleted = FALSE
    )
  );

CREATE POLICY "pinjam_up_insert" ON public.peminjaman_arsip
  FOR INSERT TO authenticated
  WITH CHECK (
    public.is_pengelola()
    AND created_by = auth.uid()
    AND EXISTS (
      SELECT 1 FROM public.arsip a
      WHERE a.id = arsip_id
        AND a.bidang = public.get_my_bidang()
        AND a.status = 'Aktif'
        AND a.is_deleted = FALSE
    )
  );

CREATE POLICY "pinjam_up_update" ON public.peminjaman_arsip
  FOR UPDATE TO authenticated
  USING (
    public.is_pengelola()
    AND created_by = auth.uid()
  );

CREATE POLICY "pinjam_ks_all" ON public.peminjaman_arsip
  FOR ALL TO authenticated
  USING (public.is_kearsipan()) WITH CHECK (public.is_kearsipan());


-- ================================================================
-- TABLE: penyusutan_arsip
-- ================================================================

ALTER TABLE public.penyusutan_arsip ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "susut_admin_all"  ON public.penyusutan_arsip;
DROP POLICY IF EXISTS "susut_tu_select"  ON public.penyusutan_arsip;
DROP POLICY IF EXISTS "susut_ks_all"     ON public.penyusutan_arsip;

CREATE POLICY "susut_admin_all" ON public.penyusutan_arsip
  FOR ALL TO authenticated
  USING (public.is_admin()) WITH CHECK (public.is_admin());

CREATE POLICY "susut_tu_select" ON public.penyusutan_arsip
  FOR SELECT TO authenticated
  USING (public.is_tu());

CREATE POLICY "susut_ks_all" ON public.penyusutan_arsip
  FOR ALL TO authenticated
  USING (public.is_kearsipan()) WITH CHECK (public.is_kearsipan());


-- ================================================================
-- TABLE: regulasi
-- ================================================================

ALTER TABLE public.regulasi ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "reg_admin_all"   ON public.regulasi;
DROP POLICY IF EXISTS "reg_all_select"  ON public.regulasi;

CREATE POLICY "reg_admin_all" ON public.regulasi
  FOR ALL TO authenticated
  USING (public.is_admin()) WITH CHECK (public.is_admin());

CREATE POLICY "reg_all_select" ON public.regulasi
  FOR SELECT TO authenticated
  USING (is_active = TRUE);


-- ================================================================
-- GRANT PERMISSIONS
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
-- SELESAI
-- ================================================================
