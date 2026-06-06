// ============================================================
// Vercel Serverless Function: /api/create-user
// Membuat user baru di Supabase Auth + update profile
// HARUS: SUPABASE_SERVICE_ROLE_KEY di environment variable Vercel
// ============================================================

export default async function handler(req, res) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const { SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY } = process.env;
  if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
    return res.status(500).json({ error: 'Konfigurasi server tidak lengkap' });
  }

  const { email, password, nama_lengkap, nip, jabatan, unit_kerja, role, bidang } = req.body;

  // Validasi
  if (!email || !password || !nama_lengkap || !role) {
    return res.status(400).json({ error: 'email, password, nama_lengkap, dan role wajib diisi' });
  }
  if (role === 'Pengelola' && !bidang) {
    return res.status(400).json({ error: 'bidang wajib diisi untuk role Pengelola' });
  }

  try {
    // 1. Buat user di Supabase Auth (butuh service role)
    const authRes = await fetch(`${SUPABASE_URL}/auth/v1/admin/users`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
        'apikey': SUPABASE_SERVICE_ROLE_KEY,
      },
      body: JSON.stringify({
        email,
        password,
        email_confirm: true,
        user_metadata: { full_name: nama_lengkap },
      }),
    });
    const authData = await authRes.json();
    if (!authRes.ok || !authData.id) {
      return res.status(400).json({ error: authData.msg || authData.message || 'Gagal membuat akun Auth' });
    }
    const userId = authData.id;

    // 2. Update profile (trigger sudah insert row default)
    const profRes = await fetch(`${SUPABASE_URL}/rest/v1/profiles?id=eq.${userId}`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
        'apikey': SUPABASE_SERVICE_ROLE_KEY,
        'Prefer': 'return=minimal',
      },
      body: JSON.stringify({
        nama_lengkap,
        nip: nip || null,
        jabatan: jabatan || null,
        unit_kerja: unit_kerja || null,
        role,
        bidang: role === 'Pengelola' ? bidang : null,
        is_active: true,
      }),
    });

    if (!profRes.ok) {
      const profErr = await profRes.text();
      return res.status(500).json({ error: 'Akun dibuat tapi profil gagal diupdate: ' + profErr });
    }

    return res.status(200).json({
      success: true,
      user_id: userId,
      message: `Akun berhasil dibuat untuk ${nama_lengkap} (${role})`,
    });

  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
}
