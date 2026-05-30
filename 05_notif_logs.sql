-- ============================================================
-- TABLE: notifikasi
-- ============================================================

CREATE TABLE public.notifikasi (
  id            BIGSERIAL PRIMARY KEY,
  judul         TEXT NOT NULL,
  pesan         TEXT NOT NULL,
  tipe          TEXT NOT NULL DEFAULT 'info',
  dibaca        BOOLEAN NOT NULL DEFAULT FALSE,
  tujuan_role   TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE public.notifikasi IS 'Notifikasi sistem untuk dashboard dan aktivitas pengguna';

CREATE INDEX idx_notifikasi_created_at
  ON public.notifikasi(created_at DESC);

CREATE INDEX idx_notifikasi_dibaca
  ON public.notifikasi(dibaca);

-- ============================================================
-- TABLE: audit_logs
-- ============================================================

CREATE TABLE public.audit_logs (
  id              BIGSERIAL PRIMARY KEY,
  user_id         UUID REFERENCES public.profiles(id),
  aktivitas       TEXT NOT NULL,
  modul           TEXT NOT NULL,
  jenis_aktivitas jenis_audit NOT NULL,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE public.audit_logs IS 'Audit trail seluruh aktivitas pengguna';

CREATE INDEX idx_audit_logs_created_at
  ON public.audit_logs(created_at DESC);

CREATE INDEX idx_audit_logs_user_id
  ON public.audit_logs(user_id);