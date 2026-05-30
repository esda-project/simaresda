// ============================================================
// SIMARESDA — Shared UI Utilities (simaresda-ui.js)
// ============================================================

// ── SUPABASE CONFIG (ganti sebelum deploy) ────────────────
window.SIMARESDA_CONFIG = {
  SUPABASE_URL:      'https://zazjmmpuqtejxynuvzfj.supabase.co',
  SUPABASE_ANON_KEY: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InphemptbXB1cXRlanh5bnV2emZqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk5NTE5NTEsImV4cCI6MjA5NTUyNzk1MX0.MAyppwvI-G2gEpG4-bE5gMH1wV-Nb4jR5kgnQkQVjto',
};

// ── DARK MODE ─────────────────────────────────────────────
function initDarkMode() {
  const saved = localStorage.getItem('simaresda-dark');
  if (saved === 'true') document.body.classList.add('dark');
  updateThemeBtn();
}
function toggleDark() {
  document.body.classList.toggle('dark');
  localStorage.setItem('simaresda-dark', document.body.classList.contains('dark'));
  updateThemeBtn();
  if (window.simaresdaCharts) window.simaresdaCharts.forEach(c => c && c.update());
}
function updateThemeBtn() {
  const btn = document.getElementById('btn-theme');
  if (btn) btn.textContent = document.body.classList.contains('dark') ? '☀️' : '🌙';
}

// ── BADGE STATUS ──────────────────────────────────────────
const STATUS_MAP = {
  'Disposisi':   'b-yellow',
  'Diproses':    'b-blue',
  'Selesai':     'b-green',
  'Arsip':       'b-gray',
  'Terkirim':    'b-green',
  'Draft':       'b-yellow',
  'Dibatalkan':  'b-red',
  'Aktif':       'b-green',
  'Inaktif':     'b-gray',
  'Dipindah':    'b-blue',
  'Dimusnahkan': 'b-red',
  'Dipinjam':    'b-blue',
  'Dikembalikan':'b-green',
  'Terlambat':   'b-red',
  'Menunggu':    'b-yellow',
  'Disetujui':   'b-green',
  'Ditolak':     'b-red',
  'Berhasil':    'b-green',
  'GAGAL':       'b-red',
};
function badge(text) {
  const cls = STATUS_MAP[text] || 'b-gray';
  return `<span class="badge ${cls}">${text}</span>`;
}
function badgePlain(text, cls) {
  return `<span class="badge ${cls || 'b-gray'}">${text}</span>`;
}

// ── MODAL ─────────────────────────────────────────────────
function openModal(id)  { const m = document.getElementById(id); if (m) { m.style.display = 'flex'; document.body.style.overflow='hidden'; } }
function closeModal(id) { const m = document.getElementById(id); if (m) { m.style.display = 'none'; document.body.style.overflow=''; } }
function closeAllModals() { document.querySelectorAll('.modal-overlay').forEach(m => { m.style.display='none'; document.body.style.overflow=''; }); }

// ── TABS ──────────────────────────────────────────────────
function switchTab(containerId, tabId, btn) {
  const container = document.getElementById(containerId);
  if (!container) return;
  container.querySelectorAll('.tab-pane').forEach(p => p.classList.remove('active'));
  container.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
  const pane = document.getElementById(tabId);
  if (pane) pane.classList.add('active');
  if (btn)  btn.classList.add('active');
}

// ── TABLE FILTER ──────────────────────────────────────────
function filterTable(tblBodyId, query) {
  const q = query.toLowerCase();
  document.querySelectorAll(`#${tblBodyId} tr`).forEach(tr => {
    tr.style.display = tr.textContent.toLowerCase().includes(q) ? '' : 'none';
  });
}

// ── TOAST NOTIFICATION ────────────────────────────────────
function showToast(msg, type = 'info', duration = 4000) {
  let container = document.getElementById('toast-container');
  if (!container) {
    container = document.createElement('div');
    container.id = 'toast-container';
    container.style.cssText = 'position:fixed;bottom:20px;right:20px;z-index:9999;display:flex;flex-direction:column;gap:8px;max-width:340px';
    document.body.appendChild(container);
  }
  const colors = { info:'var(--blueL)', success:'var(--greenL)', warn:'var(--yellowL)', danger:'var(--redL)' };
  const borders = { info:'var(--blue)', success:'var(--green)', warn:'var(--yellow)', danger:'var(--red)' };
  const toast = document.createElement('div');
  toast.style.cssText = `
    padding:10px 14px;border-radius:8px;font-size:12px;font-weight:500;
    background:${colors[type]||colors.info};color:${borders[type]||borders.info};
    border:1px solid ${borders[type]||borders.info};
    box-shadow:0 4px 16px rgba(0,0,0,.15);
    animation:slideInRight .2s ease;max-width:340px;line-height:1.5;
    font-family:'Instrument Sans',system-ui,sans-serif;
  `;
  toast.textContent = msg;
  container.appendChild(toast);
  setTimeout(() => { toast.style.opacity='0'; toast.style.transition='opacity .3s'; setTimeout(() => toast.remove(), 300); }, duration);
}

// ── EXPORT CSV ────────────────────────────────────────────
function exportCSV(tableId, filename) {
  const table = document.getElementById(tableId);
  if (!table) return;
  const rows = [];
  const ths = Array.from(table.querySelectorAll('thead th')).filter(th => !th.classList.contains('no-print'));
  rows.push(ths.map(th => '"' + th.textContent.trim() + '"').join(','));
  table.querySelectorAll('tbody tr').forEach(tr => {
    if (tr.style.display === 'none') return;
    const tds = Array.from(tr.querySelectorAll('td')).filter(td => !td.classList.contains('no-print'));
    rows.push(tds.map(td => '"' + td.textContent.trim().replace(/"/g, '""') + '"').join(','));
  });
  const blob = new Blob(['\uFEFF' + rows.join('\n')], { type: 'text/csv;charset=utf-8' });
  const a = document.createElement('a');
  a.href = URL.createObjectURL(blob);
  a.download = (filename || 'export') + '-' + new Date().toISOString().slice(0,10) + '.csv';
  a.click();
}

// ── NOMOR ROMAWI (untuk nomor surat keluar) ───────────────
const ROMAWI = ['I','II','III','IV','V','VI','VII','VIII','IX','X','XI','XII'];
function bulanRomawi(n) { return ROMAWI[(n||new Date().getMonth()+1) - 1]; }

// ── FORMAT TANGGAL ────────────────────────────────────────
const BULAN_ID = ['Januari','Februari','Maret','April','Mei','Juni','Juli','Agustus','September','Oktober','November','Desember'];
function formatTanggal(str) {
  if (!str) return '—';
  const d = new Date(str);
  return `${d.getDate()} ${BULAN_ID[d.getMonth()]} ${d.getFullYear()}`;
}

// ── CONFIRM DELETE ────────────────────────────────────────
function confirmDelete(msg, onConfirm) {
  if (confirm(msg || 'Yakin ingin menghapus data ini?')) onConfirm();
}

// ── USER SESSION (mock — ganti dengan Supabase Auth) ──────
window.SIMARESDA_USER = JSON.parse(sessionStorage.getItem('simaresda-user') || 'null');

function setUser(user) {
  window.SIMARESDA_USER = user;
  sessionStorage.setItem('simaresda-user', JSON.stringify(user));
  document.querySelectorAll('[data-user-name]').forEach(el => el.textContent = user?.nama || '—');
  document.querySelectorAll('[data-user-role]').forEach(el => el.textContent = user?.role || '—');
  document.querySelectorAll('[data-user-avatar]').forEach(el => el.textContent = (user?.nama||'?').slice(0,2).toUpperCase());
  applyRoleGuards(user?.role);
}

function applyRoleGuards(role) {
  if (!role) return;
  document.querySelectorAll('[data-require-role]').forEach(el => {
    const roles = el.dataset.requireRole.split(',').map(r => r.trim());
    if (!roles.includes(role)) el.style.display = 'none';
  });
}

function requireLogin() {
  if (!window.SIMARESDA_USER) {
    window.location.href = 'login.html';
    return false;
  }
  setUser(window.SIMARESDA_USER);
  return true;
}

function logout() {
  sessionStorage.removeItem('simaresda-user');
  window.location.href = 'login.html';
}

// ── REALTIME NOTIF BAR ────────────────────────────────────
const notifQueue = [];
function pushNotif(msg, type = 'info') {
  const time = new Date().toLocaleTimeString('id-ID',{hour:'2-digit',minute:'2-digit'});
  notifQueue.unshift({ msg, type, time, read: false });
  const bar = document.getElementById('notif-text');
  if (bar) bar.textContent = '🔔 ' + msg;
  showToast(msg, type);
  updateNotifBadge();
}
function updateNotifBadge() {
  const badge = document.getElementById('notif-count');
  const unread = notifQueue.filter(n => !n.read).length;
  if (badge) { badge.textContent = unread; badge.style.display = unread ? '' : 'none'; }
}
function openNotifModal() {
  notifQueue.forEach(n => n.read = true);
  updateNotifBadge();
  const list = document.getElementById('notif-list');
  if (!list) return;
  const typeMap = { info:'b-blue', success:'b-green', warn:'b-yellow', danger:'b-red' };
  list.innerHTML = notifQueue.length === 0
    ? '<div class="empty"><div class="empty-ico">🔔</div><div class="empty-txt">Belum ada notifikasi</div></div>'
    : notifQueue.map(n => `
      <div style="display:flex;gap:10px;padding:10px;border:1px solid var(--border);border-radius:6px;align-items:flex-start">
        <span class="badge ${typeMap[n.type]||'b-gray'}" style="white-space:nowrap">${n.time}</span>
        <span style="font-size:12px;color:var(--text)">${n.msg}</span>
      </div>`).join('');
  openModal('modal-notif');
}

// ── INIT (call on every page) ─────────────────────────────
function simaresdaInit() {
  initDarkMode();
  if (!requireLogin()) return;
  // Demo: simulate realtime ping every 15s
  setInterval(() => {
    const msgs = [
      '📥 Surat masuk baru diterima dari Kemenkes',
      '✏️ Status peminjaman ARK-2025-003 diperbarui',
      '✅ Surat keluar SK-2025-008 berhasil dikirim',
      '⚠️ Peminjaman FP-2025-002 melewati batas kembali',
    ];
    pushNotif(msgs[Math.floor(Math.random() * msgs.length)], ['info','success','warn','danger'][Math.floor(Math.random()*4)]);
  }, 15000);
}

// CSS animation for toast
const style = document.createElement('style');
style.textContent = '@keyframes slideInRight{from{transform:translateX(110%);opacity:0}to{transform:translateX(0);opacity:1}}';
document.head.appendChild(style);
