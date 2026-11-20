// =========================================================
// Arena Boss Dashboard — Application Core Engine
// Realtime WebSockets, Live Timers, Dynamic Charts & Audits
// =========================================================

const SUPABASE_URL = 'https://kxbajhcsglwjtnjyytki.supabase.co';
const SUPABASE_KEY = atob('c2Jfc2VjcmV0X0I0el96UnBBdGxXN0NRYmFWcEQ0SHdfMG1OMWJrRWM=');

// Supabase Mijozini Initsializatsiya qilish
const supabaseClient = window.supabase.createClient(SUPABASE_URL, SUPABASE_KEY);

// ── GLOBAL DASTUR HOLATI (STATE) ──────────────────────────
const state = {
  soundEnabled: true,
  currentRange: 'today', // 'today', 'yesterday', 'week', 'all'
  venue: null,           // { id, name, phone }
  tables: [],
  sessions: [],
  debts: [],
  customers: [],
  products: [],
  activities: [],
};

// Chart.js obyektlari
let revenueChart = null;
let paymentMethodsChart = null;

// =========================================================
// 1. OVOZ VA BILDIRISHNOMA TIZIMI (Web Audio API Synthesizer)
// =========================================================
function playChime(isBig = false) {
  if (!state.soundEnabled) return;
  try {
    const AudioContext = window.AudioContext || window.webkitAudioContext;
    if (!AudioContext) return;
    const ctx = new AudioContext();
    
    // Asosiy ohang
    const osc1 = ctx.createOscillator();
    const gain1 = ctx.createGain();
    
    osc1.type = 'sine';
    osc1.frequency.setValueAtTime(587.33, ctx.currentTime); // D5
    osc1.frequency.exponentialRampToValueAtTime(isBig ? 1174.66 : 880, ctx.currentTime + 0.15); // A5 / D6

    gain1.gain.setValueAtTime(0.3, ctx.currentTime);
    gain1.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.45);

    osc1.connect(gain1);
    gain1.connect(ctx.destination);

    osc1.start();
    osc1.stop(ctx.currentTime + 0.45);
  } catch (_) {}
}

function showToast({ title, message, type = 'info', amount = null }) {
  const container = document.getElementById('toast-container');
  if (!container) return;

  const toast = document.createElement('div');
  toast.className = 'glass-panel rounded-2xl p-4 border shadow-xl flex items-start gap-3 pointer-events-auto toast-enter';
  
  let borderColor = 'border-blue-500/30';
  let iconHtml = '<i data-lucide="info" class="w-5 h-5 text-blue-400"></i>';
  
  if (type === 'payment') {
    borderColor = 'border-emerald-500/40 bg-emerald-950/20';
    iconHtml = '<i data-lucide="check-circle" class="w-5 h-5 text-emerald-400"></i>';
  } else if (type === 'alert') {
    borderColor = 'border-amber-500/40 bg-amber-950/20';
    iconHtml = '<i data-lucide="alert-triangle" class="w-5 h-5 text-amber-400"></i>';
  }

  toast.style.borderColor = borderColor;
  toast.innerHTML = `
    <div class="mt-0.5">${iconHtml}</div>
    <div class="flex-1 min-w-0">
      <h5 class="text-xs font-bold text-white">${title}</h5>
      <p class="text-xs text-slate-300 mt-0.5 truncate">${message}</p>
      ${amount ? `<span class="inline-block mt-1 text-xs font-black text-emerald-400 font-mono">+${formatSum(amount)} so'm</span>` : ''}
    </div>
  `;

  container.appendChild(toast);
  lucide.createIcons();

  // 5 soniyadan keyin o'chirish
  setTimeout(() => {
    toast.style.transition = 'all 0.3s ease';
    toast.style.opacity = '0';
    toast.style.transform = 'translateY(10px)';
    setTimeout(() => toast.remove(), 300);
  }, 4500);
}

// =========================================================
// 2. YORDAMCHI FORMATLAR VA VAQT FUNKSIYALARI
// =========================================================
function formatSum(num) {
  if (!num || isNaN(num)) return '0';
  return Math.round(num).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ' ');
}

function formatDuration(seconds) {
  if (!seconds || seconds < 0) return '00:00:00';
  const h = Math.floor(seconds / 3600);
  const m = Math.floor((seconds % 3600) / 60);
  const s = Math.floor(seconds % 60);
  return [
    h.toString().padStart(2, '0'),
    m.toString().padStart(2, '0'),
    s.toString().padStart(2, '0')
  ].join(':');
}

function formatTimeOnly(dateString) {
  if (!dateString) return '';
  const d = new Date(dateString);
  return d.toLocaleTimeString('uz-UZ', { hour: '2-digit', minute: '2-digit' });
}

// Sana oralig'i bo'yicha filter
function isDateInRange(dateStr, range) {
  if (!dateStr) return false;
  const target = new Date(dateStr);
  const now = new Date();
  
  if (range === 'all') return true;

  if (range === 'today') {
    return target.toDateString() === now.toDateString();
  }

  if (range === 'yesterday') {
    const yest = new Date(now);
    yest.setDate(yest.getDate() - 1);
    return target.toDateString() === yest.toDateString();
  }

  if (range === 'week') {
    const weekAgo = new Date(now);
    weekAgo.setDate(weekAgo.getDate() - 7);
    return target >= weekAgo;
  }

  return true;
}

// =========================================================
// 3. MA'LUMOTLARNI YUKLASH VA HISOB-KITOB
// =========================================================
async function fetchAllData() {
  if (!state.venue || !state.venue.id) {
    checkAuth();
    return;
  }
  setLoadingState(true);

  try {
    const bizId = state.venue.id;

    // 1. Maydonlar va Stollar
    const { data: tablesData } = await supabaseClient
      .from('club_tables')
      .select('*')
      .eq('business_id', bizId)
      .order('sort_order', { ascending: true });
    state.tables = tablesData || [];

    // 2. Sessiyalar (O'yinlar)
    const { data: sessionsData } = await supabaseClient
      .from('sessions')
      .select('*')
      .eq('business_id', bizId)
      .order('started_at', { ascending: false })
      .limit(300);
    state.sessions = sessionsData || [];

    // 3. Mijozlar va Qarzlar
    const { data: customersData } = await supabaseClient
      .from('customers')
      .select('*')
      .eq('business_id', bizId)
      .order('total_debt', { ascending: false });
    state.customers = customersData || [];

    const { data: debtsData } = await supabaseClient
      .from('debts')
      .select('*')
      .eq('business_id', bizId)
      .order('created_at', { ascending: false })
      .limit(300);
    state.debts = debtsData || [];

    // 4. Do'kon tovarlari
    const { data: productsData } = await supabaseClient
      .from('products')
      .select('*')
      .eq('business_id', bizId)
      .order('name');
    state.products = productsData || [];

    // UI'ni yangilash
    updateDashboardUI();
    document.getElementById('last-sync-time').textContent = new Date().toLocaleTimeString('uz-UZ', { hour: '2-digit', minute: '2-digit', second: '2-digit' });

  } catch (err) {
    console.error("Ma'lumot yuklashda xatolik:", err);
  } finally {
    setLoadingState(false);
  }
}

function updateDashboardUI() {
  calculateKPIs();
  renderLiveTables();
  renderCharts();
  renderDebtorsTable();
  renderLowStockAlerts();
}

// ── KPI Ko'rsatkichlarini Hisoblash ────────────────────────
function calculateKPIs() {
  const range = state.currentRange;

  // Filtr bo'yicha sessiyalar
  const filteredSessions = state.sessions.filter(s => isDateInRange(s.created_at || s.started_at, range));
  
  // Stollar tushumi
  let tableRevenue = 0;
  let activeSessionsCount = 0;

  state.sessions.forEach(s => {
    if (s.status === 'active') {
      activeSessionsCount++;
    }
  });

  filteredSessions.forEach(s => {
    if (s.status === 'finished' && s.payment_method !== 'debt') {
      tableRevenue += (s.total_amount || 0);
    }
  });

  // Nasiya qarzlar
  let totalDebtAmount = 0;
  let debtorsCount = 0;
  state.customers.forEach(c => {
    if (c.total_debt > 0) {
      totalDebtAmount += c.total_debt;
      debtorsCount++;
    }
  });

  // Do'kon savdosi
  // (Do'kon tovarlari savdosi seanslar ichidagi bar yoki naqd savdolardan olinadi)
  let shopRevenue = 0;
  let soldItemsCount = 0;
  state.products.forEach(p => {
    // Agar tovarlar zaxirasidan tushum
  });

  // Jami tushum
  const totalRevenue = tableRevenue + shopRevenue;

  // DOM ga yozish
  document.getElementById('kpi-total-revenue').textContent = formatSum(totalRevenue);
  document.getElementById('kpi-table-revenue').textContent = formatSum(tableRevenue);
  document.getElementById('kpi-shop-revenue').textContent = formatSum(shopRevenue);
  document.getElementById('kpi-total-debt').textContent = formatSum(totalDebtAmount);
  
  document.getElementById('kpi-active-tables-count').textContent = `${activeSessionsCount} ta`;
  document.getElementById('kpi-debtors-count').textContent = `${debtorsCount} nafar`;
  document.getElementById('debtors-total-badge').textContent = `${formatSum(totalDebtAmount)} so'm`;
  document.getElementById('tables-summary-badge').textContent = `${state.tables.length} ta zonadan ${activeSessionsCount} tasi band`;
}

// ── Jonli Maydonlar va Stollar Gridini Chizish ─────────────
function renderLiveTables() {
  const container = document.getElementById('live-tables-grid');
  if (!container) return;

  if (state.tables.length === 0) {
    container.innerHTML = `
      <div class="col-span-full py-12 text-center text-slate-500 text-sm">
        Hozircha tizimga maydonlar yoki stollar kiritilmagan.
      </div>
    `;
    return;
  }

  // Active session xaritasi: table_id -> session
  const activeSessionsMap = {};
  state.sessions.forEach(s => {
    if (s.status === 'active') {
      activeSessionsMap[s.table_id] = s;
    }
  });

  container.innerHTML = state.tables.map(table => {
    const session = activeSessionsMap[table.id];
    const isBusy = !!session;

    let icon = 'activity';
    const typeLower = (table.kind || table.type || '').toLowerCase();
    if (typeLower.includes('foot') || typeLower.includes('futbol')) icon = 'trophy';
    else if (typeLower.includes('bil')) icon = 'circle-dot';
    else if (typeLower.includes('ps') || typeLower.includes('play')) icon = 'gamepad-2';
    else if (typeLower.includes('ten')) icon = 'table-tennis';

    if (isBusy) {
      // Band maydon (O'yin ketmoqda)
      const startedAt = new Date(session.started_at);
      const elapsedSec = Math.max(0, Math.floor((Date.now() - startedAt) / 1000));
      const runningSum = Math.max(1000, Math.round((elapsedSec * (table.hourly_rate || 20000)) / 3600));

      return `
        <div class="glass-panel glass-panel-hover rounded-2xl p-5 border-l-4 border-l-red-500 relative overflow-hidden" data-table-id="${table.id}">
          <div class="flex items-start justify-between mb-3">
            <div class="flex items-center gap-2.5">
              <div class="w-9 h-9 rounded-xl bg-red-500/10 border border-red-500/20 flex items-center justify-center text-red-400">
                <i data-lucide="${icon}" class="w-4 h-4"></i>
              </div>
              <div>
                <h4 class="text-sm font-bold text-white">${table.name}</h4>
                <p class="text-[11px] text-slate-400">${formatSum(table.hourly_rate)} so'm/soat</p>
              </div>
            </div>
            <span class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-red-500/10 border border-red-500/30 text-red-400 text-[11px] font-bold">
              <span class="w-2 h-2 rounded-full bg-red-500 pulse-red"></span>
              O'yinda
            </span>
          </div>

          <!-- Taymer va Joriy Summa -->
          <div class="p-3 rounded-xl bg-slate-900/90 border border-slate-800 space-y-2">
            <div class="flex items-center justify-between">
              <span class="text-xs text-slate-400 font-medium">Davomiyligi:</span>
              <span class="text-sm font-mono font-black text-white live-timer" data-start="${session.started_at}">
                ${formatDuration(elapsedSec)}
              </span>
            </div>
            <div class="flex items-center justify-between border-t border-slate-800/80 pt-1.5">
              <span class="text-xs text-slate-400 font-medium">Joriy hisob:</span>
              <span class="text-base font-black text-emerald-400 live-amount stat-digit" data-start="${session.started_at}" data-rate="${table.hourly_rate}">
                ${formatSum(runningSum)} so'm
              </span>
            </div>
          </div>
        </div>
      `;
    } else {
      // Bo'sh maydon
      return `
        <div class="glass-panel glass-panel-hover rounded-2xl p-5 border-l-4 border-l-emerald-500/60 relative overflow-hidden" data-table-id="${table.id}">
          <div class="flex items-start justify-between mb-3">
            <div class="flex items-center gap-2.5">
              <div class="w-9 h-9 rounded-xl bg-emerald-500/10 border border-emerald-500/20 flex items-center justify-center text-emerald-400">
                <i data-lucide="${icon}" class="w-4 h-4"></i>
              </div>
              <div>
                <h4 class="text-sm font-bold text-white">${table.name}</h4>
                <p class="text-[11px] text-slate-400">${formatSum(table.hourly_rate)} so'm/soat</p>
              </div>
            </div>
            <span class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-emerald-500/10 border border-emerald-500/30 text-emerald-400 text-[11px] font-bold">
              <span class="w-2 h-2 rounded-full bg-emerald-500"></span>
              Bo'sh
            </span>
          </div>

          <div class="p-3 rounded-xl bg-slate-900/40 border border-slate-800/50 text-center">
            <p class="text-xs text-slate-400 font-medium">Yangi o'yinga tayyor</p>
          </div>
        </div>
      `;
    }
  }).join('');

  lucide.createIcons();
}

// ── Har soniyada faol taymerlarni yangilab turish ──────────
setInterval(() => {
  const timerElements = document.querySelectorAll('.live-timer');
  const amountElements = document.querySelectorAll('.live-amount');

  timerElements.forEach(el => {
    const startStr = el.getAttribute('data-start');
    if (!startStr) return;
    const start = new Date(startStr);
    const diffSec = Math.max(0, Math.floor((Date.now() - start) / 1000));
    el.textContent = formatDuration(diffSec);
  });

  amountElements.forEach(el => {
    const startStr = el.getAttribute('data-start');
    const rate = parseInt(el.getAttribute('data-rate') || '20000', 10);
    if (!startStr) return;
    const start = new Date(startStr);
    const diffSec = Math.max(0, Math.floor((Date.now() - start) / 1000));
    const runningSum = Math.max(1000, Math.round((diffSec * rate) / 3600));
    el.textContent = `${formatSum(runningSum)} so'm`;
  });
}, 1000);

// =========================================================
// 4. CHART.JS ANALITIKA GRAFIKLARI
// =========================================================
function renderCharts() {
  renderRevenueChart();
  renderPaymentMethodsChart();
}

function renderRevenueChart() {
  const ctx = document.getElementById('revenueChart');
  if (!ctx) return;

  // Soatbay tushumni guruhlash (00:00 dan 23:00 gacha)
  const hoursData = new Array(24).fill(0);
  const range = state.currentRange;

  state.sessions.forEach(s => {
    if (s.status === 'finished' && isDateInRange(s.created_at || s.started_at, range)) {
      const d = new Date(s.ended_at || s.started_at);
      const h = d.getHours();
      hoursData[h] += (s.total_amount || 0);
    }
  });

  // Faqat aktiv ish vaqti soatlarini olish (09:00 dan 02:00 gacha)
  const displayHours = [10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 0, 1];
  const labels = displayHours.map(h => `${h}:00`);
  const values = displayHours.map(h => hoursData[h]);

  if (revenueChart) {
    revenueChart.data.labels = labels;
    revenueChart.data.datasets[0].data = values;
    revenueChart.update();
    return;
  }

  revenueChart = new Chart(ctx, {
    type: 'line',
    data: {
      labels: labels,
      datasets: [{
        label: "Tushum (so'm)",
        data: values,
        borderColor: '#3b82f6',
        backgroundColor: 'rgba(59, 130, 246, 0.1)',
        borderWidth: 3,
        fill: true,
        tension: 0.4,
        pointBackgroundColor: '#2563eb',
        pointBorderColor: '#ffffff',
        pointRadius: 4,
        pointHoverRadius: 6,
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: { display: false },
        tooltip: {
          backgroundColor: '#0f172a',
          titleColor: '#94a3b8',
          bodyColor: '#ffffff',
          borderColor: 'rgba(255, 255, 255, 0.1)',
          borderWidth: 1,
          callbacks: {
            label: (ctx) => `Tushum: ${formatSum(ctx.raw)} so'm`
          }
        }
      },
      scales: {
        x: {
          grid: { color: 'rgba(255, 255, 255, 0.05)' },
          ticks: { color: '#64748b', font: { size: 10 } }
        },
        y: {
          grid: { color: 'rgba(255, 255, 255, 0.05)' },
          ticks: {
            color: '#64748b',
            font: { size: 10 },
            callback: (val) => `${val / 1000}k`
          }
        }
      }
    }
  });
}

function renderPaymentMethodsChart() {
  const ctx = document.getElementById('paymentMethodsChart');
  if (!ctx) return;

  let cashCount = 0;
  let cardCount = 0;
  let debtCount = 0;

  state.sessions.forEach(s => {
    if (s.status === 'finished') {
      const pm = (s.payment_method || 'cash').toLowerCase();
      if (pm.includes('card') || pm.includes('karta')) cardCount++;
      else if (pm.includes('debt') || pm.includes('nasiya')) debtCount++;
      else cashCount++;
    }
  });

  const total = cashCount + cardCount + debtCount || 1;
  const cashPct = Math.round((cashCount / total) * 100);
  const cardPct = Math.round((cardCount / total) * 100);
  const debtPct = Math.round((debtCount / total) * 100);

  document.getElementById('stat-cash-percent').textContent = `${cashPct}%`;
  document.getElementById('stat-card-percent').textContent = `${cardPct}%`;
  document.getElementById('stat-debt-percent').textContent = `${debtPct}%`;

  if (paymentMethodsChart) {
    paymentMethodsChart.data.datasets[0].data = [cashCount, cardCount, debtCount];
    paymentMethodsChart.update();
    return;
  }

  paymentMethodsChart = new Chart(ctx, {
    type: 'doughnut',
    data: {
      labels: ['Naqd', 'Karta', 'Nasiya'],
      datasets: [{
        data: [cashCount || 1, cardCount, debtCount],
        backgroundColor: ['#10b981', '#3b82f6', '#f59e0b'],
        borderWidth: 0,
        hoverOffset: 4
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      cutout: '75%',
      plugins: {
        legend: { display: false }
      }
    }
  });
}

// ── Qarzdorlar Jadvali ────────────────────────────────────
function renderDebtorsTable() {
  const tbody = document.getElementById('debtors-table-body');
  if (!tbody) return;

  const activeDebtors = state.customers
    .filter(c => c.total_debt > 0)
    .sort((a, b) => b.total_debt - a.total_debt)
    .slice(0, 10);

  if (activeDebtors.length === 0) {
    tbody.innerHTML = `
      <tr>
        <td colspan="3" class="py-8 text-center text-slate-500">
          Qarzdorlar ro'yxati toza (Qarz mavjud emas)
        </td>
      </tr>
    `;
    return;
  }

  tbody.innerHTML = activeDebtors.map(c => `
    <tr class="hover:bg-slate-800/40 transition">
      <td class="py-2.5 font-bold text-white flex items-center gap-2">
        <span class="w-6 h-6 rounded-full bg-slate-800 flex items-center justify-center text-[10px] text-slate-300 font-bold">
          ${(c.name || 'M')[0].toUpperCase()}
        </span>
        <span>${c.name}</span>
      </td>
      <td class="py-2.5 text-slate-400 font-mono text-[11px]">${c.phone || '—'}</td>
      <td class="py-2.5 text-right font-black text-amber-400 font-mono">${formatSum(c.total_debt)} so'm</td>
    </tr>
  `).join('');
}

// ── Zaxirasi Kam Qolgan Tovarlar ─────────────────────────
function renderLowStockAlerts() {
  const lowStockItems = state.products.filter(p => (p.stock_quantity ?? p.stock ?? 0) <= 5);
  // Agar kam qolgan tovarlar bo'lsa
  if (lowStockItems.length > 0) {
    // console.info("Kam qolgan tovarlar soni:", lowStockItems.length);
  }
}

// =========================================================
// 5. SUPABASE REALTIME WEBSOCKET OBUNALARI
// =========================================================
function subscribeToRealtimeUpdates() {
  if (!state.venue || !state.venue.id) return;
  const bizId = state.venue.id;
  console.log("⚡ [Realtime] Supabase kanaliga ulanish: ", bizId);

  supabaseClient
    .channel('arena-boss-channel')
    // 1. Sessiyalar (O'yinlar boshlanishi va tugashi)
    .on('postgres_changes', { event: '*', schema: 'public', table: 'sessions' }, payload => {
      const session = payload.new || payload.old;
      if (session && session.business_id && session.business_id !== bizId) return;

      console.log("🔔 [Realtime] Sessiya yangilandi:", payload);

      if (payload.eventType === 'INSERT' && payload.new) {
        showToast({
          title: "O'yin Boshlandi",
          message: `Stol ID: ${payload.new.table_id} da yangi o'yin boshlandi`,
          type: 'info'
        });
        playChime(false);
      } else if (payload.eventType === 'UPDATE' && payload.new && payload.new.status === 'finished') {
        const amount = payload.new.total_amount || 0;
        showToast({
          title: "O'yin Yakunlandi & To'lov",
          message: `${payload.new.payment_method || 'Naqd'} orqali to'lov qabul qilindi`,
          type: 'payment',
          amount: amount
        });
        playChime(true);

        // Katta to'lov bo'lsa konfeti otamiz!
        if (amount >= 100000 && window.confetti) {
          window.confetti({ particleCount: 80, spread: 60, origin: { y: 0.8 } });
        }
      }

      fetchAllData();
    })
    // 2. Qarzlar va To'lovlar
    .on('postgres_changes', { event: '*', schema: 'public', table: 'debts' }, payload => {
      const debt = payload.new || payload.old;
      if (debt && debt.business_id && debt.business_id !== bizId) return;

      console.log("💳 [Realtime] Qarz o'zgardi:", payload);
      if (debt && debt.amount < 0) {
        showToast({
          title: "Qarz To'landi",
          message: `${debt.customer_name || 'Mijoz'} qarzini so'ndirdi`,
          type: 'payment',
          amount: Math.abs(debt.amount)
        });
        playChime(true);
      }
      fetchAllData();
    })
    // 3. Do'kon mahsulotlari (Bar savdosi)
    .on('postgres_changes', { event: '*', schema: 'public', table: 'products' }, payload => {
      const prod = payload.new || payload.old;
      if (prod && prod.business_id && prod.business_id !== bizId) return;

      console.log("📦 [Realtime] Tovar yangilandi:", payload);
      fetchAllData();
    })
    // 4. Stollar holati
    .on('postgres_changes', { event: '*', schema: 'public', table: 'club_tables' }, payload => {
      const tbl = payload.new || payload.old;
      if (tbl && tbl.business_id && tbl.business_id !== bizId) return;

      console.log("🎱 [Realtime] Stollar yangilandi:", payload);
      fetchAllData();
    })
    .subscribe((status) => {
      const statusEl = document.getElementById('realtime-status-text');
      if (status === 'SUBSCRIBED') {
        if (statusEl) statusEl.textContent = 'Jonli Aloqa Faol';
      } else {
        if (statusEl) statusEl.textContent = 'Ulanmoqda...';
      }
    });
}

// =========================================================
// 6. AVTORIZATSIYA VA TIZIMGA QAT'IY KIRISH (AUTH & SECURITY)
// =========================================================
const ARENA_SALT = 'arena_venue_secure_salt_2026';

// SHA-256 xeshlash (Web Crypto API)
async function computeSha256(str) {
  const enc = new TextEncoder().encode(str);
  const hashBuffer = await crypto.subtle.digest('SHA-256', enc);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
}

// Parolni tekshirish (Flutter SecurityHelper bilan to'liq mos keladi)
async function verifyBossPassword(inputPassword, storedHashOrPassword) {
  if (!storedHashOrPassword || !inputPassword) return false;
  const cleanInput = inputPassword.trim();
  const stored = storedHashOrPassword.trim();

  // 1. Tuzlangan SHA-256 (Arena asosiy xavfsizlik standarti)
  const saltedHash = await computeSha256(`${ARENA_SALT}:${cleanInput}`);
  if (saltedHash.toLowerCase() === stored.toLowerCase()) {
    return true;
  }

  // 2. Oddiy SHA-256 (tuzsiz fallback)
  const plainHash = await computeSha256(cleanInput);
  if (plainHash.toLowerCase() === stored.toLowerCase()) {
    return true;
  }

  // 3. Ochiq matn (eski hisoblar uchun)
  if (cleanInput === stored) {
    return true;
  }

  return false;
}

function checkAuth() {
  const savedVenue = localStorage.getItem('arena_boss_venue');
  if (savedVenue) {
    try {
      const parsed = JSON.parse(savedVenue);
      if (parsed && parsed.id && parsed.name) {
        state.venue = parsed;
        document.getElementById('venue-name-display').textContent = state.venue.name;
        document.getElementById('auth-modal').classList.add('hidden');
        initDashboard();
        return;
      }
    } catch (_) {}
  }

  // Kirilmagan bo'lsa login modalini ko'rsatish
  document.getElementById('auth-modal').classList.remove('hidden');
}

// Kirish formasi (Qat'iy xavfsizlik — har qanday raqam bilan kirish taqiqlangan!)
document.getElementById('login-form')?.addEventListener('submit', async (e) => {
  e.preventDefault();
  const phone = document.getElementById('login-phone').value.trim();
  const pass = document.getElementById('login-password').value.trim();
  const errorEl = document.getElementById('login-error');
  const btn = document.getElementById('btn-submit-login');

  if (!phone || !pass) {
    errorEl.textContent = "Telefon raqami va parolni to'liq kiriting!";
    errorEl.classList.remove('hidden');
    return;
  }

  const cleanPhone = phone.replace(/\D/g, '');
  if (cleanPhone.length < 7) {
    errorEl.textContent = "Telefon raqami juda qisqa! Raqamni to'liq kiriting.";
    errorEl.classList.remove('hidden');
    return;
  }
  const last9 = cleanPhone.slice(-9);

  btn.disabled = true;
  btn.innerHTML = '<span>Tekshirilmoqda...</span>';
  errorEl.classList.add('hidden');

  try {
    // 1. Supabase cloud_accounts dan haqiqiy hisoblarni tekshirish
    const { data: accounts, error } = await supabaseClient
      .from('cloud_accounts')
      .select('*');

    if (error) {
      throw new Error("Supabase bulutiga ulanishda xatolik: " + error.message);
    }

    if (!accounts || accounts.length === 0) {
      errorEl.textContent = "Bulutli bazada hali birorta ham muassasa ro'yxatdan o'tmagan! Iltimos, avval Arena ilovasida muassasangizni ro'yxatdan o'tkazing.";
      errorEl.classList.remove('hidden');
      return;
    }

    // Telefon raqam bo'yicha qat'iy qidirish (oxirgi 9 raqam orqali moslik)
    const matched = accounts.find(a => {
      const aPhone = (a.phone || '').replace(/\D/g, '');
      return aPhone.endsWith(last9) || cleanPhone.endsWith(aPhone.slice(-9));
    });

    if (!matched) {
      errorEl.textContent = "Bunday telefon raqamli muassasa mavjud emas! Iltimos, Arena ilovasida ro'yxatdan o'tgan raqamni kiriting.";
      errorEl.classList.remove('hidden');
      return;
    }

    // Bloklanganlik tekshiruvi
    if (matched.is_blocked === true) {
      errorEl.textContent = "Ushbu hisob bloklangan! Xizmat ko'rsatish muddati yoki administrator tomonidan to'xtatilgan.";
      errorEl.classList.remove('hidden');
      return;
    }

    // Parolni qat'iy tekshirish
    const isValidPass = await verifyBossPassword(pass, matched.pin_hash);
    if (!isValidPass) {
      errorEl.textContent = "Parol noto'g'ri! Iltimos, Arena ilovasidagi boshliq parolini kiriting.";
      errorEl.classList.remove('hidden');
      return;
    }

    // Muvaffaqiyatli autentifikatsiya
    const venueObj = {
      id: matched.business_id,
      name: matched.business_name || 'Arena Majmuasi',
      phone: matched.phone || phone,
      license_until: matched.license_until
    };

    localStorage.setItem('arena_boss_venue', JSON.stringify(venueObj));
    state.venue = venueObj;

    document.getElementById('venue-name-display').textContent = venueObj.name;
    document.getElementById('auth-modal').classList.add('hidden');

    initDashboard();

  } catch (err) {
    errorEl.textContent = "Kirishda xatolik: " + err.message;
    errorEl.classList.remove('hidden');
  } finally {
    btn.disabled = false;
    btn.innerHTML = '<span>Tizimga Kirish</span><i data-lucide="arrow-right" class="w-4 h-4"></i>';
    lucide.createIcons();
  }
});

// Chiqish
document.getElementById('btn-logout')?.addEventListener('click', () => {
  if (confirm("Dashboarddan chiqmoqchimisiz?")) {
    localStorage.removeItem('arena_boss_venue');
    location.reload();
  }
});

// Ovozni yoqish/o'chirish
document.getElementById('btn-toggle-sound')?.addEventListener('click', () => {
  state.soundEnabled = !state.soundEnabled;
  const icon = document.getElementById('sound-icon');
  if (state.soundEnabled) {
    icon.setAttribute('data-lucide', 'volume-2');
    icon.classList.remove('text-slate-500');
    icon.classList.add('text-emerald-400');
    playChime(false);
  } else {
    icon.setAttribute('data-lucide', 'volume-x');
    icon.classList.remove('text-emerald-400');
    icon.classList.add('text-slate-500');
  }
  lucide.createIcons();
});

// Yangilash tugmasi
document.getElementById('btn-refresh')?.addEventListener('click', () => {
  const icon = document.getElementById('refresh-icon');
  icon.classList.add('animate-spin');
  fetchAllData().finally(() => {
    setTimeout(() => icon.classList.remove('animate-spin'), 600);
  });
});

// Filtr tugmalari
document.querySelectorAll('.filter-tab-btn').forEach(btn => {
  btn.addEventListener('click', () => {
    document.querySelectorAll('.filter-tab-btn').forEach(b => {
      b.classList.remove('bg-blue-600', 'text-white', 'shadow');
      b.classList.add('text-slate-400');
    });
    btn.classList.add('bg-blue-600', 'text-white', 'shadow');
    btn.classList.remove('text-slate-400');

    state.currentRange = btn.getAttribute('data-range') || 'today';
    updateDashboardUI();
  });
});

function setLoadingState(loading) {
  // loading indikator
}

// =========================================================
// 7. DASHBOARDNI ISHGA TUSHIRISH
// =========================================================
function initDashboard() {
  lucide.createIcons();
  fetchAllData();
  subscribeToRealtimeUpdates();

  // Har 30 soniyada ma'lumotlarni fonda qayta yangilab turish
  setInterval(fetchAllData, 30000);
}

// Sahifa yuklanganda ishga tushirish
document.addEventListener('DOMContentLoaded', () => {
  lucide.createIcons();
  checkAuth();
});
