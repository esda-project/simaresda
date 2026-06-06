# SIMARESDA — Changelog v4.0
Tanggal: 2025-06-06

## 🔴 Perbaikan Kritis

### login.html
- HAPUS: Pilihan role manual (Admin/Pengelola/TU) — celah keamanan
- TAMBAH: Auth via Supabase signInWithPassword
- TAMBAH: Baca role dari `profiles.role` database setelah login
- TAMBAH: Validasi `is_active` — akun nonaktif ditolak
- TAMBAH: Simpan session ke sessionStorage
- UBAH: Label "Username" → "Email"

### assets/simaresda-ui.js
- TAMBAH: `getSupabase()` — Supabase client singleton
- TAMBAH: `getSessionUser()` — ambil user + profile dari DB
- TAMBAH: `requireLogin()` — guard semua halaman
- TAMBAH: `setUser()` + `applyRoleGuards()` — kontrol UI per role
- TAMBAH: `bidangLabel()` + `bidangOptions()` — helper bidang
- TAMBAH: `logout()` via Supabase Auth signOut

### assets/layout.js
- REBUILD: Sidebar menu lengkap sesuai spesifikasi
- TAMBAH: Role-aware menu (hidden per role)
- TAMBAH: Section header menu (Surat, Arsip, Referensi, Administrasi)
- TAMBAH: Badge notifikasi di nav item
- TAMBAH: Info bidang di sidebar untuk role Pengelola

## 🟡 Perbaikan Per Halaman

### index.html (Dashboard)
- TAMBAH: Filter Tahun & Bidang
- TAMBAH: Koneksi data ke `v_dashboard_summary` (Supabase view)
- TAMBAH: Grafik trend dari `v_statistik_surat_masuk` + `v_statistik_surat_keluar`
- TAMBAH: Grafik arsip per bidang dari `v_statistik_arsip`
- UBAH: Widget "Dimusnahkan" → "Penyusutan Pending"
- UBAH: Widget "Total Arsip" → terpisah "Arsip Aktif" + "Arsip Inaktif"

### surat-masuk.html
- TAMBAH: Field `bidang` (dropdown 4 pilihan) — WAJIB
- TAMBAH: Field `disposisi_ke` — dropdown pengelola sesuai bidang
- TAMBAH: Field `catatan_disposisi`, `is_rahasia`
- TAMBAH: Filter bidang di toolbar
- TAMBAH: Kolom bidang di tabel
- GANTI: Semua data ke Supabase `surat_masuk` table
- TAMBAH: Auto-generate `nomor_agenda` (SM-YYYY-NNN)
- TAMBAH: RLS-aware — Pengelola hanya lihat bidang sendiri

### surat-keluar.html
- TAMBAH: Field `bidang` — auto-isi dari profil user
- TAMBAH: Filter bidang di toolbar
- TAMBAH: Tombol "Verifikasi" untuk TU
- TAMBAH: Modal "Penomoran Resmi" untuk TU
- TAMBAH: Auto-generate `nomor_draft` (SKD-YYYY-NNN)
- GANTI: Semua data ke Supabase `surat_keluar` table

### penyimpanan.html (Arsip)
- TAMBAH: Tab Arsip Aktif / Arsip Inaktif dalam satu halaman
- TAMBAH: Field `bidang` di form arsip
- TAMBAH: Filter bidang di toolbar
- TAMBAH: Tombol "Serahkan ke Inaktif" untuk Pengelola
- GANTI: Semua data ke Supabase `arsip` table
- TAMBAH: arsip-aktif.html + arsip-inaktif.html (alias dengan default tab)

### peminjaman.html
- TAMBAH: Dropdown pilih arsip dari database (bukan input manual)
- TAMBAH: Auto-filter arsip sesuai role (Pengelola=aktif, Kearsipan=inaktif)
- TAMBAH: Auto-generate `nomor_formulir` (PM-YYYY-NNN)
- TAMBAH: Indikator merah untuk peminjaman terlambat
- TAMBAH: Tombol "Kembalikan" dengan update `tanggal_kembali_aktual`
- GANTI: Semua data ke Supabase `peminjaman_arsip` table

### pemusnahan.html (Penyusutan)
- UBAH: Nama & scope → "Penyusutan Arsip" (bukan hanya pemusnahan)
- TAMBAH: Tab filter Semua / Pemindahan / Pemusnahan / Penyerahan Permanen
- TAMBAH: Usulan penyusutan → Supabase `penyusutan_arsip` table
- TAMBAH: Tombol Setujui/Tolak untuk Unit Kearsipan & Admin
- TAMBAH: Auto-update status arsip setelah disetujui

### regulasi.html
- TAMBAH: Tab sub-menu 7 jenis (UU/PP/ANRI/Mendagri/Perda/Perwali/SE)
- TAMBAH: Field `jenis` di form tambah regulasi
- TAMBAH: Filter per jenis di toolbar
- GANTI: Semua data ke Supabase `regulasi` table

### user-management.html
- TAMBAH: Role "Unit Kearsipan" di form dan filter
- TAMBAH: Field `bidang` — muncul hanya jika role = Pengelola
- TAMBAH: Toggle aktif/nonaktif per user
- GANTI: Edit user → update Supabase `profiles` table
- TAMBAH: Buat user baru via `/api/create-user` (Vercel serverless)

## 🆕 File Baru

| File | Keterangan |
|---|---|
| `arsip-aktif.html` | Halaman khusus Arsip Aktif (default tab aktif) |
| `arsip-inaktif.html` | Halaman khusus Arsip Inaktif (default tab inaktif) |
| `api/create-user.js` | Vercel serverless — buat user Supabase Auth (butuh service role key) |
| `vercel.json` | Konfigurasi routing Vercel |
| `.env.example` | Template environment variables |

## ⚠️ Langkah Wajib Setelah Deploy

1. Jalankan `01_migration_final.sql` di Supabase project SIMARESDA
2. Jalankan `02_rls_final.sql`
3. Set environment variables di Vercel:
   - `SUPABASE_SERVICE_ROLE_KEY` (untuk /api/create-user)
4. Buat akun Admin pertama via Supabase Dashboard → Auth → Users
5. Update role di SQL:
   ```sql
   UPDATE profiles SET role='Admin', is_active=TRUE WHERE id='uuid-admin';
   ```
6. Login sebagai Admin → buat akun TU, Pengelola, Unit Kearsipan

## 🔧 Yang Masih Perlu Dikerjakan

- [ ] Upload file (PDF) ke Supabase Storage — semua form sudah punya `file_url` tapi upload handler belum
- [ ] Modul cari-arsip.html — koneksi ke Supabase
- [ ] Modul audit.html — koneksi ke `activity_log`
- [ ] Reset password halaman — sudah ada, perlu disambungkan ke Supabase
- [ ] Notifikasi realtime via Supabase Realtime
- [ ] Export PDF per surat/arsip
