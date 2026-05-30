// ============================================================
// SIMARESDA — Shared UI Utilities (REVISI PRODUKSI)
// ============================================================

// ============================================================
// SUPABASE CONFIG
// ============================================================

window.SIMARESDA_CONFIG = {
  SUPABASE_URL:
    'https://zazjmmpuqtejxynuvzfj.supabase.co',

  SUPABASE_ANON_KEY:
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InphemptbXB1cXRlanh5bnV2emZqIiwicm9sZSI6ImFub24iLCJpYXQiOj'
};

// ============================================================
// DARK MODE
// ============================================================

function initDarkMode() {
  const saved = localStorage.getItem('simas-dark');

  if (saved === 'true') {
    document.body.classList.add('dark');
  }

  updateThemeBtn();
}

function toggleDark() {
  document.body.classList.toggle('dark');

  localStorage.setItem(
    'simas-dark',
    document.body.classList.contains('dark')
  );

  updateThemeBtn();

  if (window.simasCharts) {
    window.simasCharts.forEach(chart => {
      if (chart) chart.update();
    });
  }
}

function updateThemeBtn() {
  const btn = document.getElementById('btn-theme');

  if (!btn) return;

  btn.textContent =
    document.body.classList.contains('dark')
      ? '☀️'
      : '🌙';
}

// ============================================================
// STATUS BADGE
// ============================================================

const STATUS_MAP = {
  Disposisi: 'b-yellow',
  Diproses: 'b-blue',
  Selesai: 'b-green',
  Arsip: 'b-gray',
  Terkirim: 'b-green',
  Draft: 'b-yellow',
  Dibatalkan: 'b-red',
  Aktif: 'b-green',
  Inaktif: 'b-gray',
  Dipindah: 'b-blue',
  Dimusnahkan: 'b-red',
  Dipinjam: 'b-blue',
  Dikembalikan: 'b-green',
  Terlambat: 'b-red',
  Menunggu: 'b-yellow',
  Disetujui: 'b-green',
  Ditolak: 'b-red',
  Berhasil: 'b-green',
  GAGAL: 'b-red'
};

function badge(text) {
  const cls = STATUS_MAP[text] || 'b-gray';

  return `
    <span class="badge ${cls}">
      ${text}
    </span>
  `;
}

function badgePlain(text, cls) {
  return `
    <span class="badge ${cls || 'b-gray'}">
      ${text}
    </span>
  `;
}

// ============================================================
// MODAL
// ============================================================

function openModal(id) {
  const modal = document.getElementById(id);

  if (!modal) return;

  modal.style.display = 'flex';
  document.body.style.overflow = 'hidden';
}

function closeModal(id) {
  const modal = document.getElementById(id);

  if (!modal) return;

  modal.style.display = 'none';
  document.body.style.overflow = '';
}

function closeAllModals() {
  document
    .querySelectorAll('.modal-overlay')
    .forEach(modal => {
      modal.style.display = 'none';
    });

  document.body.style.overflow = '';
}

// ============================================================
// TABS
// ============================================================

function switchTab(containerId, tabId, btn) {
  const container =
    document.getElementById(containerId);

  if (!container) return;

  container
    .querySelectorAll('.tab-pane')
    .forEach(p => p.classList.remove('active'));

  container
    .querySelectorAll('.tab-btn')
    .forEach(b => b.classList.remove('active'));

  const pane = document.getElementById(tabId);

  if (pane) pane.classList.add('active');

  if (btn) btn.classList.add('active');
}

// ============================================================
// TABLE FILTER
// ============================================================

function filterTable(tblBodyId, query) {
  const q = query.toLowerCase();

  document
    .querySelectorAll(`#${tblBodyId} tr`)
    .forEach(row => {
      row.style.display =
        row.textContent
          .toLowerCase()
          .includes(q)
          ? ''
          : 'none';
    });
}

// ============================================================
// TOAST
// ============================================================

function showToast(
  msg,
  type = 'info',
  duration = 4000
) {
  let container =
    document.getElementById('toast-container');

  if (!container) {
    container = document.createElement('div');

    container.id = 'toast-container';

    container.style.cssText = `
      position:fixed;
      bottom:20px;
      right:20px;
      z-index:9999;
      display:flex;
      flex-direction:column;
      gap:8px;
      max-width:340px;
    `;

    document.body.appendChild(container);
  }

  const colors = {
    info: 'var(--blueL)',
    success: 'var(--greenL)',
    warn: 'var(--yellowL)',
    danger: 'var(--redL)'
  };

  const borders = {
    info: 'var(--blue)',
    success: 'var(--green)',
    warn: 'var(--yellow)',
    danger: 'var(--red)'
  };

  const toast =
    document.createElement('div');

  toast.style.cssText = `
    padding:10px 14px;
    border-radius:8px;
    font-size:12px;
    font-weight:500;
    background:${colors[type] || colors.info};
    color:${borders[type] || borders.info};
    border:1px solid ${borders[type] || borders.info};
    box-shadow:0 4px 16px rgba(0,0,0,.15);
    max-width:340px;
    line-height:1.5;
  `;

  toast.textContent = msg;

  container.appendChild(toast);

  setTimeout(() => {
    toast.style.opacity = '0';

    setTimeout(() => {
      toast.remove();
    }, 300);
  }, duration);
}

// ============================================================
// EXPORT CSV
// ============================================================

function exportCSV(tableId, filename) {
  const table =
    document.getElementById(tableId);

  if (!table) return;

  const rows = [];

  const headers = Array.from(
    table.querySelectorAll('thead th')
  );

  rows.push(
    headers
      .map(h => `"${h.textContent.trim()}"`)
      .join(',')
  );

  table
    .querySelectorAll('tbody tr')
    .forEach(row => {
      const cols = Array.from(
        row.querySelectorAll('td')
      );

      rows.push(
        cols
          .map(c => `"${c.textContent.trim()}"`)
          .join(',')
      );
    });

  const blob = new Blob(
    ['\uFEFF' + rows.join('\n')],
    {
      type:
        'text/csv;charset=utf-8'
    }
  );

  const a =
    document.createElement('a');

  a.href =
    URL.createObjectURL(blob);

  a.download =
    filename +
    '-' +
    new Date()
      .toISOString()
      .slice(0, 10) +
    '.csv';

  a.click();
}

// ============================================================
// FORMAT TANGGAL
// ============================================================

const BULAN_ID = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember'
];

function formatTanggal(str) {
  if (!str) return '—';

  const d = new Date(str);

  return `${d.getDate()} ${
    BULAN_ID[d.getMonth()]
  } ${d.getFullYear()}`;
}

// ============================================================
// USER SESSION
// ============================================================

window.SIMARESDA_USER =
  JSON.parse(
    sessionStorage.getItem(
      'simas-user'
    ) || 'null'
  );

function setUser(user) {
  window.SIMARESDA_USER = user;

  sessionStorage.setItem(
    'simas-user',
    JSON.stringify(user)
  );

  document
    .querySelectorAll(
      '[data-user-name]'
    )
    .forEach(el => {
      el.textContent =
        user?.nama || '-';
    });

  document
    .querySelectorAll(
      '[data-user-role]'
    )
    .forEach(el => {
      el.textContent =
        user?.role || '-';
    });

  document
    .querySelectorAll(
      '[data-user-avatar]'
    )
    .forEach(el => {
      el.textContent =
        (user?.nama || '?')
          .substring(0, 2)
          .toUpperCase();
    });

  applyRoleGuards(user?.role);
}

function applyRoleGuards(role) {
  if (!role) return;

  document
    .querySelectorAll(
      '[data-require-role]'
    )
    .forEach(el => {
      const roles =
        el.dataset.requireRole
          .split(',')
          .map(r => r.trim());

      if (!roles.includes(role)) {
        el.style.display = 'none';
      }
    });
}

function requireLogin() {
  if (!window.SIMARESDA_USER) {
    window.location.href =
      'login.html';

    return false;
  }

  setUser(window.SIMARESDA_USER);

  return true;
}

function logout() {
  sessionStorage.removeItem(
    'simas-user'
  );

  window.location.href =
    'login.html';
}

// ============================================================
// NOTIFIKASI
// ============================================================

const notifQueue = [];

function pushNotif(
  msg,
  type = 'info'
) {
  const time =
    new Date().toLocaleTimeString(
      'id-ID',
      {
        hour: '2-digit',
        minute: '2-digit'
      }
    );

  notifQueue.unshift({
    msg,
    type,
    time,
    read: false
  });

  updateNotifBadge();

  showToast(msg, type);
}

function updateNotifBadge() {
  const badge =
    document.getElementById(
      'notif-count'
    );

  if (!badge) return;

  const unread =
    notifQueue.filter(
      n => !n.read
    ).length;

  badge.textContent = unread;

  badge.style.display =
    unread > 0
      ? ''
      : 'none';
}

function openNotifModal() {
  notifQueue.forEach(
    n => (n.read = true)
  );

  updateNotifBadge();

  const list =
    document.getElementById(
      'notif-list'
    );

  if (!list) return;

  if (notifQueue.length === 0) {
    list.innerHTML = `
      <div class="empty">
        <div class="empty-ico">🔔</div>
        <div class="empty-txt">
          Belum ada notifikasi
        </div>
      </div>
    `;
  } else {
    list.innerHTML =
      notifQueue
        .map(
          n => `
          <div class="notif-item">
            <strong>${n.time}</strong>
            <div>${n.msg}</div>
          </div>
        `
        )
        .join('');
  }

  openModal('modal-notif');
}

// ============================================================
// INIT
// ============================================================

function simasInit() {
  initDarkMode();

  if (!requireLogin()) {
    return;
  }

  updateNotifBadge();

  console.log(
    'SIMARESDA UI initialized'
  );
}

// ============================================================
// TOAST ANIMATION
// ============================================================

const style =
  document.createElement('style');

style.textContent = `
@keyframes slideInRight{
from{
transform:translateX(100%);
opacity:0;
}
to{
transform:translateX(0);
opacity:1;
}
}
`;

document.head.appendChild(style);
