# SIMARESDA — Pemetaan Schema: Existing vs Baru

Dokumen ini menjelaskan perbedaan nama kolom antara schema existing di database
dengan nama yang dipakai di spesifikasi proyek. Gunakan sebagai referensi saat
menulis query di kode aplikasi Next.js.

---

## profiles

| Spesifikasi | Nama Kolom Aktual | Tipe | Keterangan |
|---|---|---|---|
| full_name | **nama_lengkap** | TEXT | Beda nama |
| role | role | role_user | Sudah ada: 'Admin','TU','Pengelola' + baru: 'Unit Kearsipan' |
| bidang | bidang | bidang_enum | **Kolom baru ditambahkan** |
| is_active | is_active | BOOLEAN | Sudah ada |
| nip | nip | TEXT | Sudah ada |
| jabatan | jabatan | TEXT | Sudah ada |
| — | unit_kerja | TEXT | Ada di existing, teks bebas |
| phone | phone | TEXT | **Kolom baru ditambahkan** |

---

## surat_masuk

| Spesifikasi | Nama Kolom Aktual | Tipe | Keterangan |
|---|---|---|---|
| bidang | bidang | bidang_enum | **Kolom baru** |
| tujuan_disposisi | **disposisi_ke** | UUID | Beda nama, sudah ada |
| catatan_disposisi | catatan_disposisi | TEXT | **Kolom baru** |
| tanggal_disposisi | tanggal_disposisi | TIMESTAMPTZ | **Kolom baru** |
| disposisi_oleh | disposisi_oleh | UUID | **Kolom baru** |
| file_lampiran_urls | file_lampiran_urls | TEXT[] | **Kolom baru** |
| jumlah_lampiran | jumlah_lampiran | SMALLINT | **Kolom baru** |
| is_rahasia | is_rahasia | BOOLEAN | **Kolom baru** |
| status_disposisi | **status** | status_surat_masuk | Beda nama. Nilai: 'Disposisi','Diproses','Selesai','Arsip' |
| — | kategori | kategori_arsip | Ada di existing |
| — | sifat | sifat_surat | Ada di existing |
| — | is_deleted | BOOLEAN | Soft delete, existing |

---

## surat_keluar

| Spesifikasi | Nama Kolom Aktual | Tipe | Keterangan |
|---|---|---|---|
| bidang | bidang | bidang_enum | **Kolom baru** |
| unit_pengelola | unit_pengelola | UUID | **Kolom baru** |
| file_draft_url | file_draft_url | TEXT | **Kolom baru** |
| file_final_url | file_final_url | TEXT | **Kolom baru** |
| catatan_verifikasi | catatan_verifikasi | TEXT | **Kolom baru** |
| diverifikasi_oleh | diverifikasi_oleh | UUID | **Kolom baru** |
| tanggal_verifikasi | tanggal_verifikasi | TIMESTAMPTZ | **Kolom baru** |
| diberi_nomor_oleh | diberi_nomor_oleh | UUID | **Kolom baru** |
| tanggal_penomoran | tanggal_penomoran | TIMESTAMPTZ | **Kolom baru** |
| is_rahasia | is_rahasia | BOOLEAN | **Kolom baru** |
| status | **status** | status_surat_keluar | Nilai existing: 'Draft','Terkirim','Dibatalkan' |
| — | kategori | kategori_arsip | Ada di existing |
| — | sifat | sifat_surat | Ada di existing |
| — | penandatangan | TEXT | Ada di existing |
| — | tembusan | TEXT[] | Ada di existing |
| — | is_deleted | BOOLEAN | Soft delete, existing |

---

## arsip

| Spesifikasi | Nama Kolom Aktual | Tipe | Keterangan |
|---|---|---|---|
| judul | **perihal** | TEXT | Beda nama |
| tahun | **tahun_arsip** | SMALLINT | Beda nama |
| jenis_arsip | **jenis** | jenis_arsip | Beda nama. Nilai: 'Arsip Aktif','Arsip Inaktif' |
| status_arsip | **status** | status_arsip | Beda nama. Nilai: 'Aktif','Inaktif','Dipindah','Dimusnahkan' |
| bidang | bidang | bidang_enum | **Kolom baru** |
| file_urls | file_urls | TEXT[] | **Kolom baru** |
| diserahkan_oleh | diserahkan_oleh | UUID | **Kolom baru** |
| diterima_oleh | diterima_oleh | UUID | **Kolom baru** |
| tanggal_inaktif | tanggal_inaktif | DATE | **Kolom baru** |
| lokasi_rak | lokasi_rak | TEXT | Sudah ada |
| — | lokasi_box | TEXT | Ada di existing |
| — | lokasi_laci | TEXT | Ada di existing |
| retensi_aktif | retensi_aktif | SMALLINT | Sudah ada |
| retensi_inaktif | retensi_inaktif | SMALLINT | Sudah ada |
| — | retensi_is_permanen | BOOLEAN | Ada di existing |
| — | kategori | kategori_arsip | Ada di existing |
| — | is_deleted | BOOLEAN | Soft delete, existing |

---

## peminjaman_arsip

| Spesifikasi | Nama Kolom Aktual | Tipe | Keterangan |
|---|---|---|---|
| nama_peminjam | nama_peminjam | TEXT | Sudah ada |
| instansi_peminjam | instansi_peminjam | TEXT | **Kolom baru** |
| peminjam_id | peminjam_id | UUID | **Kolom baru** (FK ke profiles) |
| dilayani_oleh | dilayani_oleh | UUID | **Kolom baru** |
| status | status | status_pinjam | Nilai: 'Dipinjam','Dikembalikan','Terlambat' |
| — | nomor_formulir | TEXT | Ada di existing |
| — | jabatan_peminjam | TEXT | Ada di existing |
| — | nip_peminjam | TEXT | Ada di existing |
| — | unit_peminjam | TEXT | Ada di existing |
| — | disetujui_oleh | UUID | Ada di existing |
| — | dikembalikan_oleh | UUID | Ada di existing |

---

## penyusutan_arsip *(tabel baru)*

| Kolom | Tipe | Keterangan |
|---|---|---|
| id | UUID | PK |
| arsip_id | UUID | FK → arsip |
| jenis_penyusutan | jenis_penyusutan_enum | 'Pemindahan','Pemusnahan','Penyerahan Permanen' |
| tanggal_usul | DATE | — |
| tanggal_persetujuan | DATE | — |
| tanggal_pelaksanaan | DATE | — |
| status | status_musna | 'Menunggu','Disetujui','Ditolak','Selesai' |
| keterangan | TEXT | — |
| dasar_hukum | TEXT | Referensi JRA |
| diusulkan_oleh | UUID | FK → profiles |
| disetujui_oleh | UUID | FK → profiles |
| berita_acara_url | TEXT | Path file BA |

---

## regulasi

| Spesifikasi | Nama Kolom Aktual | Tipe | Keterangan |
|---|---|---|---|
| jenis | jenis | jenis_regulasi_enum | **Kolom baru** |
| tentang | tentang | TEXT | **Kolom baru** |
| judul | judul | TEXT | Sudah ada |
| nomor | nomor | TEXT | Sudah ada |
| tahun | tahun | SMALLINT | Sudah ada |
| instansi_penerbit | **instansi** | TEXT | Beda nama |
| file_url | file_url | TEXT | Sudah ada |
| — | kode | TEXT | Ada di existing |
| — | link_url | TEXT | Ada di existing |
| — | urutan | SMALLINT | Ada di existing |

---

## Enum Reference

### bidang_enum *(baru)*
| Value | Label UI |
|---|---|
| UMUM | Umum / Sekretariat |
| BUMD | BUMD |
| PEREKONOMIAN | Perekonomian |
| SDA_DBHCHT | SDA & DBH CHT |

### role_user *(ditambah 1 nilai)*
| Value | Keterangan |
|---|---|
| Admin | Full access |
| TU | Tata Usaha |
| Pengelola | Unit Pengelola (per bidang) |
| Unit Kearsipan | **Baru ditambahkan** |

### status_surat_masuk *(existing)*
`Disposisi` → `Diproses` → `Selesai` → `Arsip`

### status_surat_keluar *(existing)*
`Draft` → `Terkirim` / `Dibatalkan`

### status_arsip *(existing)*
`Aktif` → `Inaktif` → `Dipindah` / `Dimusnahkan`

### status_pinjam *(existing)*
`Dipinjam` → `Dikembalikan` / `Terlambat`

### status_musna *(existing, dipakai penyusutan_arsip)*
`Menunggu` → `Disetujui` / `Ditolak` → `Selesai`

---

## Catatan Penting untuk Developer

1. **Selalu gunakan nama kolom aktual** (kolom kanan) saat menulis query Supabase di Next.js
2. **`arsip.perihal`** = judul arsip, **`arsip.tahun_arsip`** = tahun
3. **`surat_masuk.disposisi_ke`** = UUID user tujuan disposisi (bukan `tujuan_disposisi`)
4. **Soft delete**: `surat_masuk`, `surat_keluar`, `arsip` pakai `is_deleted = FALSE` — selalu tambahkan filter ini di setiap query SELECT
5. **`profiles.nama_lengkap`** bukan `full_name`
6. **`regulasi.instansi`** bukan `instansi_penerbit`
