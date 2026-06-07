// ============================================================
// SIMARESDA — Shared Layout Injector v4.0
// PERBAIKAN: Menu lengkap sesuai spesifikasi + role-aware
// ============================================================

function buildSidebar(activeNav) {
  const user = window.SIMARESDA_USER || {};
  const role = user.role || '';

  // Semua menu — visibility dikontrol oleh data-require-role
  const navItems = [
    // Menu Utama
    { section: 'Menu Utama' },
    { id:'dashboard',  icon:'📊', label:'Dashboard',           href:'dashboard.html' },
    // Surat
    { section: 'Surat' },
    { id:'masuk',      icon:'📥', label:'Surat Masuk',          href:'surat-masuk.html',
      badge:'', requireRole:'Admin,TU,Pengelola,Unit Kearsipan' },
    { id:'keluar',     icon:'📤', label:'Surat Keluar',         href:'surat-keluar.html',
      requireRole:'Admin,TU,Pengelola,Unit Kearsipan' },
    // Arsip
    { section: 'Arsip' },
    { id:'arsip-aktif',   icon:'🗄️', label:'Arsip Aktif',       href:'arsip-aktif.html',
      requireRole:'Admin,TU,Pengelola' },
    { id:'arsip-inaktif', icon:'📦', label:'Arsip Inaktif',     href:'arsip-inaktif.html',
      requireRole:'Admin,TU,Unit Kearsipan' },
    { id:'peminjaman',    icon:'🔖', label:'Peminjaman Arsip',   href:'peminjaman.html',
      requireRole:'Admin,Pengelola,Unit Kearsipan' },
    { id:'penyusutan',    icon:'🗑️', label:'Penyusutan Arsip',  href:'penyusutan.html',
      requireRole:'Admin,Unit Kearsipan' },
    // Referensi
    { section: 'Referensi' },
    { id:'regulasi',   icon:'📋', label:'Regulasi',              href:'regulasi.html' },
    { id:'audit',      icon:'📝', label:'Audit Trail',           href:'audit.html',
      requireRole:'Admin' },
    // Admin
    { section: 'Administrasi', requireRole:'Admin' },
    { id:'pengguna',   icon:'👥', label:'Pengguna',              href:'user-management.html',
      requireRole:'Admin' },
  ];

  let html = '';
  let currentSection = '';

  for (const item of navItems) {
    // Section header
    if (item.section) {
      // Sembunyikan section header jika role tidak punya akses
      if (item.requireRole) {
        const roles = item.requireRole.split(',').map(r => r.trim());
        if (!roles.includes(role)) continue;
      }
      html += `<div class="nav-section">${item.section}</div>`;
      continue;
    }
    // Nav item
    if (item.requireRole) {
      const roles = item.requireRole.split(',').map(r => r.trim());
      if (!roles.includes(role)) continue;
    }
    const active    = activeNav === item.id ? 'active' : '';
    const badgeHTML = item.badge !== undefined
      ? `<span class="nav-badge" id="nav-badge-${item.id}" style="display:none">0</span>` : '';
    html += `
    <a class="nav-item ${active}" href="${item.href}">
      <span class="nav-icon">${item.icon}</span>
      ${item.label}
      ${badgeHTML}
    </a>`;
  }

  // Info bidang untuk Pengelola
  const bidangInfo = (role === 'Pengelola' && user.bidang)
    ? `<div style="font-size:10px;padding:4px 10px;margin-bottom:6px;background:var(--blueL,#EBF4FF);color:var(--blue,#1D4ED8);border-radius:6px;text-align:center;font-weight:600;">
         Bidang: ${(window.BIDANG_LABEL||{})[user.bidang]||user.bidang}
       </div>` : '';

  return `
  <div id="sidebar">
    <div class="logo-wrap">
      <div class="logo-icon">📁</div>
      <div>
        <div class="logo-title">SIMARESDA</div>
        <div class="logo-year">Arsip Daerah · 2025–2030</div>
      </div>
    </div>
    <nav class="nav-scroll">${html}</nav>
    <div class="sidebar-footer">
      ${bidangInfo}
      <div class="user-pill">
        <div class="avatar" data-user-avatar>${(user.nama_lengkap||'AD').slice(0,2).toUpperCase()}</div>
        <div class="user-info">
          <div class="user-name" data-user-name>${user.nama_lengkap||'Pengguna'}</div>
          <div class="user-role" data-user-role>${role||'—'} · Aktif</div>
        </div>
      </div>
      <button class="logout-btn" onclick="logout()">↩ Keluar dari Sistem</button>
    </div>
  </div>`;
}

function buildTopbar(title) {
  return `
  <div class="notif-bar" id="notif-bar" onclick="openNotifModal()">
    <span class="notif-pulse"></span>
    <span id="notif-text">🔔 Sistem siap — Notifikasi aktif</span>
  </div>
  <div class="topbar">
    <div class="topbar-title">${title}</div>
    <div class="search-wrap no-print">
      <span class="search-ico">🔍</span>
      <input type="text" placeholder="Cari arsip, nomor surat..." id="global-search">
    </div>
    <div class="topbar-actions no-print">
      <button class="icon-btn" id="btn-theme" onclick="toggleDark()" title="Ganti tema">🌙</button>
      <button class="icon-btn" onclick="window.print()" title="Cetak halaman">🖨️</button>
      <div style="position:relative">
        <button class="icon-btn" onclick="openNotifModal()" title="Notifikasi">🔔</button>
        <span id="notif-count" style="position:absolute;top:-4px;right:-4px;background:var(--red);color:#fff;font-size:9px;font-weight:700;width:16px;height:16px;border-radius:50%;display:none;align-items:center;justify-content:center">0</span>
      </div>
    </div>
  </div>`;
}

function buildNotifModal() {
  return `
  <div class="modal-overlay" id="modal-notif" style="display:none" onclick="if(event.target===this)closeModal('modal-notif')">
    <div class="modal" style="width:min(420px,95vw)">
      <div class="modal-header">
        <div class="modal-title">🔔 Notifikasi</div>
        <button class="icon-btn" onclick="closeModal('modal-notif')">✕</button>
      </div>
      <div class="modal-body" id="notif-list" style="display:flex;flex-direction:column;gap:8px;max-height:400px;overflow-y:auto">
        <div class="empty"><div class="empty-ico">🔔</div><div class="empty-txt">Belum ada notifikasi</div></div>
      </div>
    </div>
  </div>`;
}

function injectLayout(activeNav, pageTitle) {
  const app = document.getElementById('app');
  if (!app) return;
  app.innerHTML = `
    ${buildSidebar(activeNav)}
    <div id="main">
      ${buildTopbar(pageTitle)}
      <div class="content" id="content"></div>
    </div>
    ${buildNotifModal()}
  `;
  const contentSlot = document.getElementById('page-content-slot');
  const target      = document.getElementById('content');
  if (contentSlot && target) {
    target.innerHTML = '';
    target.appendChild(contentSlot);
    contentSlot.style.display = '';
  }
}
