// ============================================================
// SIMARESDA — Shared Layout Injector (layout.js)
// Inject sidebar + topbar + notif modal into every page
// ============================================================

function buildSidebar(activeNav) {
  const navItems = [
    { id:'dashboard',  icon:'📊', label:'Dashboard',        href:'index.html'       },
    { id:'masuk',      icon:'📥', label:'Surat Masuk',       href:'surat-masuk.html', badge:'12' },
    { id:'keluar',     icon:'📤', label:'Surat Keluar',      href:'surat-keluar.html' },
    { id:'peminjaman', icon:'🔖', label:'Peminjaman Arsip',  href:'peminjaman.html'  },
    { id:'penyimpanan',icon:'🗄️', label:'Penyimpanan Arsip', href:'penyimpanan.html' },
    { id:'pemusnahan', icon:'🗑️', label:'Pemusnahan Arsip',  href:'pemusnahan.html', requireRole:'Admin,Pengelola' },
    { id:'regulasi',   icon:'📋', label:'Regulasi',          href:'regulasi.html'    },
    { id:'audit',      icon:'📝', label:'Audit Trail',       href:'audit.html',      requireRole:'Admin,Pengelola' },
  ];

  const user = window.SIMARESDA_USER || {};
  const navHTML = navItems.map(item => {
    const active = activeNav === item.id ? 'active' : '';
    const badgeHTML = item.badge ? `<span class="nav-badge" id="nav-badge-${item.id}">${item.badge}</span>` : '';
    const roleAttr  = item.requireRole ? `data-require-role="${item.requireRole}"` : '';
    return `
    <a class="nav-item ${active}" href="${item.href}" ${roleAttr}>
      <span class="nav-icon">${item.icon}</span>
      ${item.label}
      ${badgeHTML}
    </a>`;
  });

  const sections = `
    <div class="nav-section">Menu Utama</div>
    ${navHTML.slice(0,3).join('')}
    <div class="nav-section">Arsip</div>
    ${navHTML.slice(3,6).join('')}
    <div class="nav-section">Referensi</div>
    ${navHTML.slice(6).join('')}
  `;

  return `
  <div id="sidebar">
    <div class="logo-wrap">
      <div class="logo-icon">📁</div>
      <div>
        <div class="logo-title">SIMARESDA</div>
        <div class="logo-year">Arsip Daerah · 2025–2030</div>
      </div>
    </div>
    <nav class="nav-scroll">${sections}</nav>
    <div class="sidebar-footer">
      <div class="user-pill">
        <div class="avatar" data-user-avatar>${(user.nama||'AD').slice(0,2).toUpperCase()}</div>
        <div class="user-info">
          <div class="user-name" data-user-name>${user.nama||'Administrator'}</div>
          <div class="user-role" data-user-role>${user.role||'Admin'} · Aktif</div>
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
    <span id="notif-text">🔔 Sistem siap — Notifikasi real-time aktif</span>
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
      <div class="content" id="content">
        ${app.getAttribute('data-content') || ''}
      </div>
    </div>
    ${buildNotifModal()}
  `;
  // Move page content
  const contentSlot = document.getElementById('page-content-slot');
  const target      = document.getElementById('content');
  if (contentSlot && target) {
    target.innerHTML = '';
    target.appendChild(contentSlot);
    contentSlot.style.display = '';
  }
}
