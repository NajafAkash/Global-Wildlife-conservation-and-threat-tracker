// ══════════════════════════════════════════
//  Wildlife Tracker — script.js  (complete)
// ══════════════════════════════════════════

// ── UTILITIES & XSS PREVENTION ───────────
const escapeHTML = str => {
  if (str === null || str === undefined) return '';
  return String(str).replace(/[&<>'"]/g, match => ({
    '&': '&amp;', '<': '&lt;', '>': '&gt;', "'": '&#39;', '"': '&quot;'
  }[match]));
};

// ── AUTH GUARD ───────────────────────────
const getToken = () => localStorage.getItem('wt_token');
const getUser  = () => { try { return JSON.parse(localStorage.getItem('wt_user')||'{}'); } catch{ return {}; } };

function logout() {
  localStorage.removeItem('wt_token');
  localStorage.removeItem('wt_user');
  window.location.href = '/';
}

if (!getToken()) { window.location.href = '/'; }

// ── API HELPERS ──────────────────────────
const AUTH = () => ({ 'Authorization': `Bearer ${getToken()}`, 'Content-Type': 'application/json' });

async function apiGet(path) {
  const r = await fetch(path, { headers: AUTH() });
  if (r.status === 401) { logout(); return null; }
  if (!r.ok) throw new Error(`HTTP Error: ${r.status}`);
  return r.json();
}
async function apiPost(path, body) {
  const r = await fetch(path, { method: 'POST', headers: AUTH(), body: JSON.stringify(body) });
  if (r.status === 401) { logout(); return null; }
  if (!r.ok) throw new Error(`HTTP Error: ${r.status}`);
  return { ok: r.ok, status: r.status, data: await r.json() };
}
async function apiPut(path, body) {
  const r = await fetch(path, { method: 'PUT', headers: AUTH(), body: JSON.stringify(body) });
  if (r.status === 401) { logout(); return null; }
  if (!r.ok) throw new Error(`HTTP Error: ${r.status}`);
  return { ok: r.ok, status: r.status, data: await r.json() };
}
async function apiDel(path) {
  const r = await fetch(path, { method: 'DELETE', headers: AUTH() });
  if (r.status === 401) { logout(); return null; }
  if (!r.ok) throw new Error(`HTTP Error: ${r.status}`);
  return { ok: r.ok, data: await r.json() };
}

// ── TOAST ────────────────────────────────
function toast(msg, type='success') {
  const t = document.getElementById('toast');
  t.textContent = msg;
  t.className = `toast toast-${type} show`;
  setTimeout(() => t.classList.remove('show'), 3000);
}

// ── THEME ────────────────────────────────
function toggleTheme() {
  const body = document.body;
  const icon1 = document.getElementById('theme-icon');
  const icon2 = document.getElementById('theme-icon-settings');
  const isLight = body.getAttribute('data-theme') === 'light';
  body.setAttribute('data-theme', isLight ? '' : 'light');
  const ic = isLight ? 'fa-moon' : 'fa-sun';
  if (icon1) icon1.className = `fa-solid ${ic}`;
  if (icon2) icon2.className = `fa-solid ${ic}`;
}

// ── MODAL HELPERS ────────────────────────
function openModal(id) { document.getElementById(id).classList.add('open'); }
function closeModal(id) { document.getElementById(id).classList.remove('open'); }
document.addEventListener('click', e => {
  if (e.target.classList.contains('modal-overlay')) e.target.classList.remove('open');
});

// ── PAGE NAVIGATION ──────────────────────
const PAGE_TITLES = {
  dashboard:'Dashboard', species:'Species Registry', threats:'Threat Monitoring',
  locations:'Locations', reports:'Field Reports', plans:'Prevention Plans',
  orgs:'Organizations', analytics:'Analytics', users:'User Management', settings:'Settings'
};
let _chartsInited = {};

function showPage(name, el) {
  document.querySelectorAll('.page').forEach(p => p.classList.remove('active'));
  document.querySelectorAll('.nav-item').forEach(n => n.classList.remove('active'));
  const pg = document.getElementById('pg-' + name);
  if (pg) pg.classList.add('active');
  if (el) el.classList.add('active');
  document.getElementById('page-title').innerHTML =
    `${PAGE_TITLES[name]||name}${name==='dashboard'?' <span>Overview</span>':''}`;

  // Lazy-load page data
  const loaders = {
    dashboard: loadDashboard,
    species:   loadSpecies,
    threats:   loadThreatsPage,
    locations: loadLocations,
    reports:   () => loadReports('all'),
    plans:     loadPlans,
    analytics: loadAnalytics,
    orgs:      loadOrgs,
    users:     loadUsers,
  };
  if (loaders[name]) loaders[name]();
  document.querySelector('.sidebar').classList.remove('show');
}

// ── GLOBAL SEARCH ────────────────────────
function globalSearchFn() {
  const q = document.getElementById('globalSearch').value.trim();
  if (!q) return;
  showPage('species', document.querySelector('.nav-item:nth-child(2)'));
  document.getElementById('speciesSearch').value = q;
  renderSpeciesTable();
}

// ══════════════════════════════════════════
//  FALLBACK DATA
// ══════════════════════════════════════════
const STATUS_MAP = {
  1:{code:'EX',name:'Extinct',color:'#1a1a2e'},
  2:{code:'EW',name:'Extinct in Wild',color:'#4a0e0e'},
  3:{code:'CR',name:'Critically Endangered',color:'#dc2626'},
  4:{code:'EN',name:'Endangered',color:'#ea580c'},
  5:{code:'VU',name:'Vulnerable',color:'#d97706'},
  6:{code:'NT',name:'Near Threatened',color:'#ca8a04'},
  7:{code:'LC',name:'Least Concern',color:'#16a34a'},
};
const CODE_COLOR = {EX:'#1a1a2e',EW:'#4a0e0e',CR:'#dc2626',EN:'#ea580c',VU:'#d97706',NT:'#ca8a04',LC:'#16a34a'};

const FB_SPECIES = [
  {species_id:1,common_name:'Giant Panda',scientific_name:'Ailuropoda melanoleuca',family:'Ursidae',population_est:1864,population_trend:'increasing',status:{code:'EN',name:'Endangered',color_hex:'#ea580c'},habitat:{name:'Bamboo Forests of Sichuan'}},
  {species_id:2,common_name:'Snow Leopard',scientific_name:'Panthera uncia',family:'Felidae',population_est:4500,population_trend:'decreasing',status:{code:'EN',name:'Endangered',color_hex:'#ea580c'},habitat:{name:'Central Asian Highlands'}},
  {species_id:3,common_name:'Amur Leopard',scientific_name:'Panthera pardus orientalis',family:'Felidae',population_est:84,population_trend:'increasing',status:{code:'CR',name:'Critically Endangered',color_hex:'#dc2626'},habitat:{name:'Russian Far East Taiga'}},
  {species_id:4,common_name:'Sumatran Orangutan',scientific_name:'Pongo abelii',family:'Hominidae',population_est:13846,population_trend:'decreasing',status:{code:'CR',name:'Critically Endangered',color_hex:'#dc2626'},habitat:{name:'Amazon Rainforest'}},
];
const FB_THREATS = [
  {threat_id:1,name:'Illegal Poaching',category:'poaching',severity:'critical',affected_species:8},
  {threat_id:2,name:'Deforestation',category:'habitat_loss',severity:'critical',affected_species:7},
];
const FB_LOCATIONS = [
  {location_id:1,name:'Wolong Nature Reserve',country:'China',region:'Sichuan',latitude:30.92,longitude:102.98,area_km2:2000,is_protected:true},
  {location_id:2,name:'Snow Leopard Habitat',country:'Mongolia',region:'Altai Mountains',latitude:48.0,longitude:89.0,area_km2:50000,is_protected:false},
];
const FB_REPORTS = [
  {report_id:1,species_name:'Vaquita',report_date:'2025-05-02',location:{name:'Gulf of California, Mexico'},population_obs:2,health_status:'stressed',notes:'Only 2 individuals confirmed alive.',verified:false},
];
const FB_PLANS = [
  {plan_id:1,title:'Giant Panda Recovery Program',species_id:1,status:'active',success_rate:82.5,budget_usd:5000000,start_date:'2020-01-01',end_date:'2025-12-31',action_steps:'Expand bamboo corridors.'},
];

// ── STATE ────────────────────────────────
let _species   = [];
let _threats   = [];
let _locations = [];
let _reports   = [];
let _plans     = [];
let _leafletMap = null;
let _reportsFilter = 'all';
let _speciesPage = 1;
const PER_PAGE = 8;

// ══════════════════════════════════════════
//  DASHBOARD
// ══════════════════════════════════════════
async function loadDashboard() {
  if (_chartsInited.dashboard) return;

  let stats = null, statusDist = null, topThreats = null;
  try {
    const d = await apiGet('/api/analytics/dashboard');
    if (d && d.totals) {
      stats      = d.totals;
      statusDist = d.status_dist;
      topThreats = d.top_threats;
    }
  } catch(e) { console.error(e); }

  const total = stats ? stats.total_species : FB_SPECIES.length;
  const risk  = stats ? stats.at_risk_species : FB_SPECIES.filter(s=>['CR','EN'].includes(s.status?.code)).length;
  const locs  = stats ? stats.total_locations : FB_LOCATIONS.length;
  const plans = stats ? stats.total_plans : FB_PLANS.length;
  
  document.getElementById('st-total').textContent = total;
  document.getElementById('st-risk').textContent  = risk;
  document.getElementById('st-threats').textContent = FB_THREATS.length;
  document.getElementById('st-locs').textContent  = locs;
  document.getElementById('st-plans').textContent = plans;

  await loadSpeciesData();
  renderDashTable(_species.slice(0, 8));

  initTrendChart();
  initStatusChart(statusDist);
  initThreatPie();

  renderThreatList();
  renderRecentReports();

  _chartsInited.dashboard = true;
}

function renderDashTable(data) {
  document.getElementById('dashTbody').innerHTML = buildSpeciesRows(data);
}

function filterDashTable(code, el) {
  document.querySelectorAll('.filter-pill').forEach(p => p.classList.remove('active'));
  el.classList.add('active');
  const filtered = code === 'all' ? _species.slice(0,8) : _species.filter(s => s.status?.code === code);
  renderDashTable(filtered);
}

// ══════════════════════════════════════════
//  SPECIES
// ══════════════════════════════════════════
async function loadSpeciesData() {
  if (_species.length) return;
  try {
    const d = await apiGet('/api/species?per_page=100');
    _species = (d && d.data) ? d.data : [];
  } catch(e) { 
    console.error("Database connection failed:", e);
    toast("Warning: Backend disconnected. Loading local offline data.", "error");
    _species = FB_SPECIES; 
  }
}

async function loadSpecies() {
  await loadSpeciesData();
  renderSpeciesTable();
  populateSpeciesDropdowns();
}

function renderSpeciesTable() {
  const q      = (document.getElementById('speciesSearch')?.value || '').toLowerCase();
  const status = document.getElementById('statusFilter')?.value || '';
  let data = _species.filter(s => {
    const matchQ = !q || s.common_name.toLowerCase().includes(q) || s.scientific_name.toLowerCase().includes(q) || (s.family||'').toLowerCase().includes(q);
    const matchS = !status || s.status?.code === status;
    return matchQ && matchS;
  });
  const total = data.length;
  const pages = Math.ceil(total / PER_PAGE);
  if (_speciesPage > pages) _speciesPage = 1;
  const slice = data.slice((_speciesPage-1)*PER_PAGE, _speciesPage*PER_PAGE);
  document.getElementById('speciesTbody').innerHTML = buildSpeciesRows(slice, true);
  renderPagination('speciesPagination', _speciesPage, pages, p => { _speciesPage = p; renderSpeciesTable(); });
}

function buildSpeciesRows(data, showFamily=false) {
  if (!data.length) return `<tr><td colspan="7" style="text-align:center;color:var(--text3);padding:30px;">No species found.</td></tr>`;
  const maxPop = 500000;
  return data.map(s => {
    const code  = s.status?.code || '—';
    const color = s.status?.color_hex || CODE_COLOR[code] || '#6b8f6b';
    const pop   = s.population_est || 0;
    const pct   = Math.min((pop/maxPop)*100,100).toFixed(0);
    const trend = escapeHTML(s.population_trend) || 'unknown';
    const tIcon = trend==='increasing'?`<i class="fa-solid fa-arrow-trend-up" style="color:var(--accent)"></i>`:trend==='decreasing'?`<i class="fa-solid fa-arrow-trend-down" style="color:var(--red)"></i>`:`<i class="fa-solid fa-minus" style="color:var(--text3)"></i>`;
    const habitat = escapeHTML(s.habitat?.name) || '—';
    return `<tr>
      <td><div class="species-name">${escapeHTML(s.common_name)}</div><div class="sci-name">${escapeHTML(s.scientific_name)}</div></td>
      <td><span class="status-badge" style="color:${color};border-color:${color}33;background:${color}11">${escapeHTML(code)}</span></td>
      <td><div style="font-family:'DM Mono',monospace;font-size:12px;color:var(--text1)">${pop.toLocaleString()}</div><div class="pop-bar"><div class="pop-bar-fill" style="width:${pct}%"></div></div></td>
      <td><div style="display:flex;align-items:center;gap:5px;font-size:12px;color:var(--text2);text-transform:capitalize">${tIcon} ${trend}</div></td>
      ${showFamily ? `<td><span style="font-size:12px;color:var(--text3)">${escapeHTML(s.family)||'—'}</span></td>` : ''}
      <td><span style="font-size:12px;color:var(--text3)">${habitat}</span></td>
      <td><div class="action-icons">
        <button class="act-btn" title="View" onclick="viewSpecies(${s.species_id})"><i class="fa-solid fa-eye"></i></button>
        <button class="act-btn" title="Edit" onclick="openSpeciesModal('edit',${s.species_id})"><i class="fa-solid fa-pen"></i></button>
        <button class="act-btn" title="Delete" style="color:var(--red)" onclick="deleteSpecies(${s.species_id})"><i class="fa-solid fa-trash"></i></button>
      </div></td>
    </tr>`;
  }).join('');
}

function populateSpeciesDropdowns() {
  const opts = ['<option value="">— Select Species —</option>',
    ..._species.map(s => `<option value="${s.species_id}">${escapeHTML(s.common_name)}</option>`)
  ].join('');
  ['rf-species','pf-species'].forEach(id => {
    const el = document.getElementById(id);
    if (el) el.innerHTML = opts;
  });
}

// SPECIES MODAL
let _speciesModalMode = 'add';

function openSpeciesModal(mode, id=null) {
  _speciesModalMode = mode;
  document.getElementById('speciesViewBody').style.display = 'none';
  document.getElementById('speciesFormBody').style.display = 'block';
  document.getElementById('speciesSubmitBtn').style.display = 'inline-flex';

  if (mode === 'add') {
    document.getElementById('speciesModalTitle').textContent = 'Add New Species';
    document.getElementById('sf-id').value = '';
    ['sf-common','sf-sci','sf-family','sf-era','sf-img','sf-desc'].forEach(i => document.getElementById(i).value = '');
    document.getElementById('sf-pop').value = '';
    document.getElementById('sf-status').value = '4';
    document.getElementById('sf-trend').value = 'unknown';
    document.getElementById('sf-habitat').value = '';
  } else if (mode === 'edit') {
    const s = _species.find(sp => sp.species_id == id);
    if (!s) return;
    document.getElementById('speciesModalTitle').textContent = 'Edit Species';
    document.getElementById('sf-id').value         = s.species_id;
    document.getElementById('sf-common').value     = s.common_name || '';
    document.getElementById('sf-sci').value        = s.scientific_name || '';
    document.getElementById('sf-family').value     = s.family || '';
    document.getElementById('sf-pop').value        = s.population_est || '';
    document.getElementById('sf-trend').value      = s.population_trend || 'unknown';
    document.getElementById('sf-era').value        = s.origin_era || '';
    document.getElementById('sf-img').value        = s.image_url || '';
    document.getElementById('sf-desc').value       = s.description || '';
    document.getElementById('sf-status').value     = s.status_id || '4';
    document.getElementById('sf-habitat').value    = s.habitat_id || '';
  }
  openModal('speciesModal');
}

async function viewSpecies(id) {
  const s = _species.find(sp => sp.species_id == id);
  if (!s) return;
  document.getElementById('speciesModalTitle').textContent = 'Species Details';
  document.getElementById('speciesFormBody').style.display = 'none';
  document.getElementById('speciesSubmitBtn').style.display = 'none';
  const code  = s.status?.code || '—';
  const color = s.status?.color_hex || CODE_COLOR[code] || '#6b8f6b';
  document.getElementById('speciesViewBody').style.display = 'block';
  document.getElementById('speciesViewBody').innerHTML = `
    <div style="display:grid;grid-template-columns:1fr 1fr;gap:16px;">
      ${viewRow('Common Name', escapeHTML(s.common_name))}
      ${viewRow('Scientific Name', `<em>${escapeHTML(s.scientific_name)}</em>`)}
      ${viewRow('Family', escapeHTML(s.family)||'—')}
      ${viewRow('Conservation Status', `<span class="status-badge" style="color:${color};border-color:${color}33;background:${color}11">${escapeHTML(code)} — ${escapeHTML(s.status?.name)||'—'}</span>`)}
      ${viewRow('Population', (s.population_est||0).toLocaleString())}
      ${viewRow('Population Trend', escapeHTML(s.population_trend)||'—')}
      ${viewRow('Habitat', escapeHTML(s.habitat?.name)||'—')}
      ${viewRow('Origin Era', escapeHTML(s.origin_era)||'—')}
    </div>
    ${s.description ? `<div style="margin-top:16px;padding:14px;background:var(--surface);border-radius:8px;font-size:13px;color:var(--text2);line-height:1.6;">${escapeHTML(s.description)}</div>` : ''}
    ${s.image_url ? `<div style="margin-top:14px;"><img src="${escapeHTML(s.image_url)}" style="width:100%;border-radius:8px;max-height:200px;object-fit:cover;" onerror="this.style.display='none'"></div>` : ''}
  `;
  openModal('speciesModal');
}

function viewRow(label, value) {
  return `<div><div style="font-size:11px;color:var(--text3);text-transform:uppercase;letter-spacing:.06em;margin-bottom:4px;">${label}</div><div style="font-size:13px;color:var(--text1);">${value}</div></div>`;
}

async function submitSpeciesForm() {
  const common = document.getElementById('sf-common').value.trim();
  const sci    = document.getElementById('sf-sci').value.trim();
  if (!common || !sci) { toast('Common name and scientific name are required.','error'); return; }

  const body = {
    common_name: common, scientific_name: sci,
    family: document.getElementById('sf-family').value,
    population_est: parseInt(document.getElementById('sf-pop').value)||null,
    population_trend: document.getElementById('sf-trend').value,
    status_id: parseInt(document.getElementById('sf-status').value),
    habitat_id: parseInt(document.getElementById('sf-habitat').value)||null,
    origin_era: document.getElementById('sf-era').value,
    image_url: document.getElementById('sf-img').value,
    description: document.getElementById('sf-desc').value,
  };

  const id = document.getElementById('sf-id').value;
  try {
    let res = _speciesModalMode === 'add' ? await apiPost('/api/species', body) : await apiPut(`/api/species/${id}`, body);
    if (res && res.ok) {
      toast(_speciesModalMode==='add' ? 'Species added successfully!' : 'Species updated!');
      closeModal('speciesModal');
      _species = []; 
      await loadSpeciesData();
      renderSpeciesTable();
      renderDashTable(_species.slice(0,8));
      populateSpeciesDropdowns();
    } else {
      toast((res?.data?.error || 'Failed to save species.'), 'error');
    }
  } catch(e) {
    if (_speciesModalMode === 'add') {
      const sid = Date.now();
      const sc = document.getElementById('sf-status').options[document.getElementById('sf-status').selectedIndex];
      _species.push({...body, species_id: sid,
        status: {code: sc.text.split(' — ')[0], name: sc.text.split(' — ')[1], color_hex: CODE_COLOR[sc.text.split(' — ')[0]]},
        habitat: {name: document.getElementById('sf-habitat').options[document.getElementById('sf-habitat').selectedIndex]?.text || '—'}
      });
    } else {
      const idx = _species.findIndex(s => s.species_id == id);
      if (idx > -1) _species[idx] = {..._species[idx], ...body};
    }
    toast(_speciesModalMode==='add' ? 'Species added (offline mode).' : 'Species updated (offline mode).');
    closeModal('speciesModal');
    renderSpeciesTable();
    renderDashTable(_species.slice(0,8));
  }
}

async function deleteSpecies(id) {
  if (!confirm('Delete this species? This action cannot be undone.')) return;
  try {
    const res = await apiDel(`/api/species/${id}`);
    if (res && res.ok) { toast('Species deleted.'); }
    else toast('Deleted (offline mode).');
  } catch(e) { toast('Deleted (offline mode).'); }
  _species = _species.filter(s => s.species_id != id);
  renderSpeciesTable();
  renderDashTable(_species.slice(0,8));
}

// ══════════════════════════════════════════
//  THREATS
// ══════════════════════════════════════════
async function loadThreatsPage() {
  if (_chartsInited.threats) { renderThreatsTable(); return; }
  try {
    const d = await apiGet('/api/threats');
    _threats = (d && Array.isArray(d)) ? d : [];
  } catch(e) { _threats = FB_THREATS; }

  renderThreatsTable();
  initThreatsCharts();
  _chartsInited.threats = true;
}

function renderThreatsTable() {
  document.getElementById('threatsTbody').innerHTML = _threats.map(t => {
    const sev = t.severity || 'low';
    const sevColor = sev==='critical'?'#dc2626':sev==='high'?'#ea580c':sev==='moderate'?'#d97706':'#16a34a';
    return `<tr>
      <td><span style="font-weight:500;color:var(--text1)">${escapeHTML(t.name)}</span></td>
      <td><span style="font-size:12px;color:var(--text3);text-transform:capitalize">${escapeHTML(t.category||'').replace('_',' ')}</span></td>
      <td><span class="status-badge" style="color:${sevColor};border-color:${sevColor}33;background:${sevColor}11;text-transform:capitalize">${escapeHTML(sev)}</span></td>
      <td><span style="font-family:'DM Mono',monospace;font-size:14px;font-weight:500;color:var(--text1)">${t.affected_species||0}</span> <span style="font-size:12px;color:var(--text3)">species</span></td>
      <td><div class="action-icons">
        <button class="act-btn" title="Edit" onclick="openThreatModal(${t.threat_id})"><i class="fa-solid fa-pen"></i></button>
      </div></td>
    </tr>`;
  }).join('');
}

function openThreatModal(id=null) {
  document.getElementById('threatModalTitle').textContent = id ? 'Edit Threat' : 'Add Threat';
  document.getElementById('tf-id').value = id || '';
  if (!id) { ['tf-name','tf-desc'].forEach(i=>document.getElementById(i).value=''); }
  else {
    const t = _threats.find(x=>x.threat_id==id);
    if (t) {
      document.getElementById('tf-name').value = t.name;
      document.getElementById('tf-cat').value  = t.category;
      document.getElementById('tf-severity').value = t.severity;
      document.getElementById('tf-desc').value = t.description||'';
    }
  }
  openModal('threatModal');
}

async function submitThreatForm() {
  const name = document.getElementById('tf-name').value.trim();
  if (!name) { toast('Threat name is required.','error'); return; }
  const body = {
    name, category: document.getElementById('tf-cat').value,
    severity: document.getElementById('tf-severity').value,
    description: document.getElementById('tf-desc').value,
  };
  const id = document.getElementById('tf-id').value;
  try {
    const res = id ? await apiPut(`/api/threats/${id}`, body) : await apiPost('/api/threats', body);
    if (res && res.ok) toast(id?'Threat updated!':'Threat added!');
    else toast(res?.data?.error||'Saved (offline).','error');
  } catch(e) { toast('Saved (offline mode).'); }
  closeModal('threatModal');
  _chartsInited.threats = false;
  _threats = [];
  loadThreatsPage();
}

// ══════════════════════════════════════════
//  LOCATIONS & MAP
// ══════════════════════════════════════════
async function loadLocations() {
  try {
    const d = await apiGet('/api/locations');
    _locations = (d && Array.isArray(d)) ? d : [];
  } catch(e) { _locations = FB_LOCATIONS; }

  renderLocationsTable();
  initLeafletMap();
}

function renderLocationsTable() {
  document.getElementById('locationsTbody').innerHTML = _locations.map(l => `
    <tr>
      <td style="color:var(--text1);font-weight:500;">${escapeHTML(l.name)||'—'}</td>
      <td>${escapeHTML(l.country)}</td>
      <td><span style="color:var(--text3);font-size:12px;">${escapeHTML(l.region)||'—'}</span></td>
      <td><span style="font-family:'DM Mono',monospace;font-size:11px;color:var(--text3);">${parseFloat(l.latitude).toFixed(4)}, ${parseFloat(l.longitude).toFixed(4)}</span></td>
      <td><span style="font-family:'DM Mono',monospace;font-size:12px;">${l.area_km2 ? Number(l.area_km2).toLocaleString() : '—'}</span></td>
      <td>${l.is_protected ? '<span style="color:var(--accent);font-size:12px;"><i class="fa-solid fa-shield-halved"></i> Yes</span>' : '<span style="color:var(--text3);font-size:12px;">No</span>'}</td>
      <td><div class="action-icons"><button class="act-btn" onclick="flyToLocation(${l.latitude},${l.longitude})"><i class="fa-solid fa-location-crosshairs"></i></button></div></td>
    </tr>`).join('');
}

function initLeafletMap() {
  if (_leafletMap) { _leafletMap.invalidateSize(); return; }
  _leafletMap = L.map('leafletMap', { zoomControl: true }).setView([20, 10], 2);
  L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    attribution: '© OpenStreetMap', maxZoom: 18,
  }).addTo(_leafletMap);

  _locations.forEach(loc => {
    const color = loc.is_protected ? '#4ade80' : (loc.name && loc.name.toLowerCase().includes('leopard') ? '#f87171' : '#fbbf24');
    const marker = L.circleMarker([parseFloat(loc.latitude), parseFloat(loc.longitude)], {
      radius: 9, fillColor: color, color: 'rgba(255,255,255,0.4)', weight: 2, fillOpacity: 0.85
    });
    marker.bindPopup(`
      <div style="font-family:'DM Sans',sans-serif;min-width:160px;">
        <div style="font-weight:600;font-size:13px;margin-bottom:4px;">${escapeHTML(loc.name)||'Unknown'}</div>
        <div style="font-size:12px;color:#666;">${escapeHTML(loc.country)}${loc.region?', '+escapeHTML(loc.region):''}</div>
        ${loc.area_km2 ? `<div style="font-size:11px;color:#888;margin-top:4px;">Area: ${Number(loc.area_km2).toLocaleString()} km²</div>` : ''}
        <div style="font-size:11px;margin-top:4px;color:${loc.is_protected?'#22c55e':'#f97316'}">${loc.is_protected?'🛡️ Protected Zone':'⚠️ Unprotected'}</div>
      </div>
    `);
    marker.addTo(_leafletMap);
  });
}

function flyToLocation(lat, lng) {
  showPage('locations', document.querySelector('[onclick*="locations"]'));
  setTimeout(() => { if (_leafletMap) _leafletMap.flyTo([lat, lng], 7, { duration: 1.5 }); }, 300);
}

function filterLocations() {
  const q = document.getElementById('locSearch').value.toLowerCase();
  const filtered = _locations.filter(l =>
    (l.name||'').toLowerCase().includes(q) || l.country.toLowerCase().includes(q) || (l.region||'').toLowerCase().includes(q)
  );
  document.getElementById('locationsTbody').innerHTML = filtered.map(l => `
    <tr>
      <td style="color:var(--text1);font-weight:500;">${escapeHTML(l.name)||'—'}</td>
      <td>${escapeHTML(l.country)}</td>
      <td><span style="color:var(--text3);font-size:12px;">${escapeHTML(l.region)||'—'}</span></td>
      <td><span style="font-family:'DM Mono',monospace;font-size:11px;color:var(--text3);">${parseFloat(l.latitude).toFixed(4)}, ${parseFloat(l.longitude).toFixed(4)}</span></td>
      <td>${l.area_km2 ? Number(l.area_km2).toLocaleString() : '—'}</td>
      <td>${l.is_protected?'<span style="color:var(--accent);font-size:12px;"><i class="fa-solid fa-shield-halved"></i> Yes</span>':'<span style="color:var(--text3);font-size:12px;">No</span>'}</td>
      <td><div class="action-icons"><button class="act-btn" onclick="flyToLocation(${l.latitude},${l.longitude})"><i class="fa-solid fa-location-crosshairs"></i></button></div></td>
    </tr>`).join('');
}

function openLocationModal() { openModal('locationModal'); }

async function submitLocationForm() {
  const country = document.getElementById('lf-country').value.trim();
  const lat     = document.getElementById('lf-lat').value;
  const lng     = document.getElementById('lf-lng').value;
  if (!country || !lat || !lng) { toast('Country, latitude and longitude are required.','error'); return; }
  const body = {
    name: document.getElementById('lf-name').value,
    country, region: document.getElementById('lf-region').value,
    latitude: parseFloat(lat), longitude: parseFloat(lng),
    area_km2: parseFloat(document.getElementById('lf-area').value)||null,
    is_protected: document.getElementById('lf-protected').checked,
  };
  try {
    const res = await apiPost('/api/locations', body);
    if (res && res.ok) toast('Location added!');
    else { _locations.push({...body, location_id: Date.now()}); toast('Added (offline mode).'); }
  } catch(e) { _locations.push({...body, location_id: Date.now()}); toast('Added (offline mode).'); }
  closeModal('locationModal');
  renderLocationsTable();
}

// ══════════════════════════════════════════
//  REPORTS
// ══════════════════════════════════════════
async function loadReports(filter='all') {
  _reportsFilter = filter;
  try {
    const d = await apiGet('/api/reports?per_page=50');
    _reports = (d && d.data) ? d.data : [];
  } catch(e) { _reports = FB_REPORTS; }
  renderReportsList();
  renderRecentReports();
}

function filterReports(f, el) {
  _reportsFilter = f;
  document.querySelectorAll('#pg-reports .filter-pill').forEach(p => p.classList.remove('active'));
  el.classList.add('active');
  renderReportsList();
}

function renderReportsList() {
  let data = [..._reports];
  if (_reportsFilter === 'verified')  data = data.filter(r => r.verified);
  if (_reportsFilter === 'pending')   data = data.filter(r => !r.verified);

  if (!data.length) {
    document.getElementById('reportsList').innerHTML = '<div style="text-align:center;color:var(--text3);padding:40px;">No reports found.</div>';
    return;
  }

  document.getElementById('reportsList').innerHTML = data.map(r => {
    const dot = r.health_status==='healthy'?'#4ade80':r.health_status==='stressed'?'#fbbf24':'#f87171';
    const loc = r.location ? r.location.name : '—';
    return `<div class="report-item">
      <div class="report-dot" style="background:${dot}"></div>
      <div class="report-body" style="flex:1">
        <div style="display:flex;justify-content:space-between;align-items:center;">
          <div class="report-species">${escapeHTML(r.species_name)||'Unknown Species'}</div>
          <div style="font-size:12px;color:var(--text3);font-family:'DM Mono',monospace;">Observations: ${r.population_obs||0}</div>
        </div>
        <div class="report-meta">
          <span>${escapeHTML(r.report_date)}</span><span>•</span><span>${escapeHTML(loc)}</span>
          ${r.verified?'<span style="font-size:10px;color:var(--accent);display:inline-flex;align-items:center;gap:3px;"><i class="fa-solid fa-check"></i> Verified</span>':'<span style="font-size:10px;color:var(--amber);">⏳ Pending</span>'}
        </div>
        <div class="report-note">${escapeHTML(r.notes)||''}</div>
      </div>
    </div>`;
  }).join('');
}

function renderRecentReports() {
  const el = document.getElementById('recentReports');
  if (!el) return;
  const data = _reports.slice(0, 4);
  el.innerHTML = data.map(r => {
    const dot = r.health_status==='healthy'?'#4ade80':r.health_status==='stressed'?'#fbbf24':'#f87171';
    const loc = r.location ? r.location.name : '—';
    return `<div class="report-item">
      <div class="report-dot" style="background:${dot}"></div>
      <div class="report-body">
        <div style="display:flex;justify-content:space-between;"><div class="report-species">${escapeHTML(r.species_name)||'Unknown'}</div><span style="font-size:11px;color:var(--text3);font-family:'DM Mono',monospace;">${r.population_obs||0} obs.</span></div>
        <div class="report-meta"><span>${escapeHTML(r.report_date)}</span><span>•</span><span>${escapeHTML(loc)}</span>${r.verified?'<span style="font-size:10px;color:var(--accent);"><i class="fa-solid fa-check"></i> Verified</span>':'<span style="font-size:10px;color:var(--amber);">⏳ Pending</span>'}</div>
        <div class="report-note" style="font-size:12px;">${escapeHTML(r.notes)||''}</div>
      </div>
    </div>`;
  }).join('');
}

function openReportModal() {
  document.getElementById('rf-date').value = new Date().toISOString().split('T')[0];
  populateSpeciesDropdowns();
  const lsel = document.getElementById('rf-location');
  lsel.innerHTML = ['<option value="">— Select Location —</option>',
    ..._locations.map(l => `<option value="${l.location_id}">${escapeHTML(l.name||l.country)}</option>`)
  ].join('');
  openModal('reportModal');
}

async function submitReport() {
  const sid = document.getElementById('rf-species').value;
  const notes = document.getElementById('rf-notes').value.trim();
  if (!sid) { toast('Please select a species.','error'); return; }
  if (!notes) { toast('Field notes are required.','error'); return; }
  const body = {
    species_id: parseInt(sid),
    location_id: parseInt(document.getElementById('rf-location').value)||null,
    report_date: document.getElementById('rf-date').value,
    population_obs: parseInt(document.getElementById('rf-obs').value)||null,
    health_status: document.getElementById('rf-health').value,
    notes,
  };
  try {
    const res = await apiPost('/api/reports', body);
    if (res && res.ok) { toast('Report submitted successfully!'); }
    else toast('Submitted (offline mode).');
  } catch(e) { toast('Submitted (offline mode).'); }

  const sp = _species.find(s => s.species_id == sid);
  const loc = _locations.find(l => l.location_id == body.location_id);
  _reports.unshift({...body, report_id: Date.now(), species_name: sp?.common_name||'Unknown', location: loc||null, verified: false});
  closeModal('reportModal');
  renderReportsList();
  renderRecentReports();
}

// ══════════════════════════════════════════
//  PREVENTION PLANS
// ══════════════════════════════════════════
async function loadPlans() {
  try {
    const d = await apiGet('/api/plans');
    _plans = (d && Array.isArray(d)) ? d : [];
  } catch(e) { _plans = FB_PLANS; }
  renderPlansTable();
}

function renderPlansTable() {
  document.getElementById('plansTbody').innerHTML = _plans.map(p => {
    const sp   = _species.find(s => s.species_id == p.species_id);
    const stColor = p.status==='active'?'var(--accent)':p.status==='completed'?'var(--blue)':p.status==='cancelled'?'var(--red)':'var(--text3)';
    return `<tr>
      <td><div style="font-weight:500;color:var(--text1);font-size:13px;">${escapeHTML(p.title)}</div></td>
      <td><span style="font-size:12px;color:var(--text2);">${escapeHTML(sp?.common_name)||'—'}</span></td>
      <td><span style="font-size:12px;color:var(--text3);">—</span></td>
      <td><span class="status-badge" style="color:${stColor};border-color:${stColor}33;background:${stColor}11;text-transform:capitalize">${escapeHTML(p.status)}</span></td>
      <td>${p.success_rate!=null?`<div style="font-family:'DM Mono',monospace;font-size:13px;">${p.success_rate}%</div><div class="pop-bar" style="width:80px;"><div class="pop-bar-fill" style="width:${p.success_rate}%;background:${p.success_rate>70?'var(--accent)':p.success_rate>40?'var(--amber)':'var(--red)'}"></div></div>`:'—'}</td>
      <td><span style="font-family:'DM Mono',monospace;font-size:12px;color:var(--text2);">${p.budget_usd?'$'+Number(p.budget_usd).toLocaleString():'—'}</span></td>
      <td><div class="action-icons">
        <button class="act-btn" onclick="openPlanModal('edit',${p.plan_id})"><i class="fa-solid fa-pen"></i></button>
      </div></td>
    </tr>`;
  }).join('');
}

function openPlanModal(mode, id=null) {
  populateSpeciesDropdowns();
  document.getElementById('planModalTitle').textContent = mode==='add' ? 'New Prevention Plan' : 'Edit Prevention Plan';
  document.getElementById('pf-id').value = id || '';
  if (mode==='edit' && id) {
    const p = _plans.find(x=>x.plan_id==id);
    if (p) {
      document.getElementById('pf-title').value   = p.title;
      document.getElementById('pf-species').value = p.species_id;
      document.getElementById('pf-status').value  = p.status;
      document.getElementById('pf-start').value   = p.start_date||'';
      document.getElementById('pf-end').value     = p.end_date||'';
      document.getElementById('pf-budget').value  = p.budget_usd||'';
      document.getElementById('pf-rate').value    = p.success_rate||'';
      document.getElementById('pf-steps').value   = p.action_steps||'';
    }
  } else {
    ['pf-title','pf-start','pf-end','pf-budget','pf-rate','pf-steps'].forEach(i=>document.getElementById(i).value='');
  }
  openModal('planModal');
}

async function submitPlanForm() {
  const title = document.getElementById('pf-title').value.trim();
  const sid   = document.getElementById('pf-species').value;
  const steps = document.getElementById('pf-steps').value.trim();
  if (!title||!sid||!steps) { toast('Title, species and action steps are required.','error'); return; }
  const body = {
    title, species_id: parseInt(sid), status: document.getElementById('pf-status').value,
    start_date: document.getElementById('pf-start').value||null,
    end_date: document.getElementById('pf-end').value||null,
    budget_usd: parseFloat(document.getElementById('pf-budget').value)||null,
    success_rate: parseFloat(document.getElementById('pf-rate').value)||null,
    action_steps: steps,
  };
  const id = document.getElementById('pf-id').value;
  try {
    const res = id ? await apiPut(`/api/plans/${id}`, body) : await apiPost('/api/plans', body);
    if (res?.ok) toast(id?'Plan updated!':'Plan created!');
    else toast('Saved (offline mode).');
  } catch(e) { toast('Saved (offline mode).'); }
  closeModal('planModal');
  _plans = [];
  await loadPlans();
}

// ══════════════════════════════════════════
//  ANALYTICS, ORGS, USERS, CHARTS & INIT
// ══════════════════════════════════════════
async function loadAnalytics() {
  if (_chartsInited.analytics) return;
  document.getElementById('an-reports').textContent  = _reports.length || '47';
  document.getElementById('an-verified').textContent = _reports.filter(r=>r.verified).length || '38';
  document.getElementById('an-success').textContent  = '71%';
  document.getElementById('an-unplanned').textContent = '12';

  new Chart(document.getElementById('analyticsChart'), {
    type:'bar',
    data:{
      labels: _plans.length ? _plans.map(p=>p.title.substring(0,25)+'…') : ['Giant Panda Plan','Snow Leopard Init.','Amur Leopard Corridor','African Elephant Plan'],
      datasets:[{label:'Success Rate %',
        data: _plans.length ? _plans.map(p=>p.success_rate||0) : [82.5,65,55,71],
        backgroundColor:['#4ade80','#fbbf24','#f87171','#60a5fa','#a78bfa'],borderRadius:6,borderWidth:0}]
    },
    options:{responsive:true,maintainAspectRatio:false,plugins:{legend:{display:false}},
      scales:{x:{grid:{color:'#2d3d2d'},ticks:{color:'#a5c8a5',font:{size:11}}},
              y:{grid:{color:'#2d3d2d'},ticks:{color:'#6b8f6b',callback:v=>v+'%'},max:100}}}
  });

  const trendCounts = {increasing:0,stable:0,decreasing:0,unknown:0};
  _species.forEach(s => { const t=s.population_trend||'unknown'; trendCounts[t]=(trendCounts[t]||0)+1; });
  new Chart(document.getElementById('trendPieChart'), {
    type:'doughnut',
    data:{labels:['Increasing','Stable','Decreasing','Unknown'],
      datasets:[{data:[trendCounts.increasing,trendCounts.stable,trendCounts.decreasing,trendCounts.unknown],
        backgroundColor:['#4ade80','#60a5fa','#f87171','#6b8f6b'],borderWidth:0}]},
    options:{responsive:true,maintainAspectRatio:false,cutout:'60%',
      plugins:{legend:{labels:{color:'#a5c8a5',font:{size:11}},position:'bottom'},
               tooltip:{backgroundColor:'#1e2a1e',borderColor:'#2d3d2d',borderWidth:1}}}
  });
  _chartsInited.analytics = true;
}

async function loadOrgs() {
  const orgs = [
    {name:'World Wildlife Fund',type:'ngo',country:'Switzerland',website:'wwf.org',contact_email:'contact@wwf.org'},
    {name:'IUCN',type:'ngo',country:'Switzerland',website:'iucn.org',contact_email:'info@iucn.org'},
    {name:'Snow Leopard Trust',type:'ngo',country:'USA',website:'snowleopard.org',contact_email:'info@snowleopard.org'},
  ];
  document.getElementById('orgsTbody').innerHTML = orgs.map(o=>`<tr>
    <td style="color:var(--text1);font-weight:500;">${o.name}</td>
    <td><span class="status-badge" style="color:var(--accent);border-color:var(--accent)33;background:var(--accent)11;text-transform:uppercase;">${o.type}</span></td>
    <td>${o.country}</td>
    <td><a href="https://${o.website}" target="_blank" style="color:var(--blue);font-size:12px;">${o.website}</a></td>
    <td style="font-size:12px;color:var(--text3);">${o.contact_email}</td>
    <td><div class="action-icons"><button class="act-btn"><i class="fa-solid fa-pen"></i></button></div></td>
  </tr>`).join('');
}
function openOrgModal() { openModal('orgModal'); }

async function loadUsers() {
  const u = getUser();
  if (u.role !== 'admin') {
    document.getElementById('usersTbody').innerHTML = '<tr><td colspan="6" style="text-align:center;color:var(--text3);padding:30px;">Admin access required.</td></tr>';
    return;
  }
  document.getElementById('usersTbody').innerHTML = `
    <tr><td style="color:var(--text1);font-weight:500;">admin</td><td style="color:var(--text2);">admin@wildlife.org</td><td><span class="status-badge" style="color:var(--red);border-color:var(--red)33;background:var(--red)11;">Admin</span></td><td>WWF</td><td style="color:var(--text3);">Today</td><td><span style="color:var(--accent);font-size:12px;"><i class="fa-solid fa-circle"></i> Active</span></td></tr>
    <tr><td style="color:var(--text1);font-weight:500;">researcher1</td><td style="color:var(--text2);">r1@wildlife.org</td><td><span class="status-badge" style="color:var(--blue);border-color:var(--blue)33;background:var(--blue)11;">Researcher</span></td><td>IUCN</td><td style="color:var(--text3);">Yesterday</td><td><span style="color:var(--accent);font-size:12px;"><i class="fa-solid fa-circle"></i> Active</span></td></tr>
    <tr><td style="color:var(--text1);font-weight:500;">viewer1</td><td style="color:var(--text2);">viewer@wildlife.org</td><td><span class="status-badge" style="color:var(--text3);border-color:var(--text3)33;background:var(--text3)11;">Viewer</span></td><td>—</td><td style="color:var(--text3);">—</td><td><span style="color:var(--accent);font-size:12px;"><i class="fa-solid fa-circle"></i> Active</span></td></tr>
  `;
}

const CHART_OPTS = { color: '#6b8f6b', grid: '#2d3d2d', tooltip: { backgroundColor:'#1e2a1e',borderColor:'#2d3d2d',borderWidth:1,titleColor:'#e8f5e9',bodyColor:'#a5c8a5' } };

function initTrendChart() {
  new Chart(document.getElementById('trendChart'), {
    type:'line',
    data:{labels:['Dec','Jan','Feb','Mar','Apr','May'],datasets:[
      {label:'Sightings',data:[312,287,356,401,378,447],borderColor:'#4ade80',backgroundColor:'rgba(74,222,128,.08)',tension:.4,borderWidth:2,pointRadius:3,pointBackgroundColor:'#4ade80',fill:true},
      {label:'At-Risk',data:[82,85,84,87,88,89],borderColor:'#f87171',backgroundColor:'rgba(248,113,113,.05)',tension:.4,borderWidth:2,pointRadius:3,pointBackgroundColor:'#f87171',fill:true,yAxisID:'y1'},
    ]},
    options:{responsive:true,maintainAspectRatio:false,plugins:{legend:{display:false},tooltip:CHART_OPTS.tooltip},
      scales:{x:{grid:{color:CHART_OPTS.grid},ticks:{color:CHART_OPTS.color,font:{size:11}}},
              y:{grid:{color:CHART_OPTS.grid},ticks:{color:CHART_OPTS.color,font:{size:11}},position:'left'},
              y1:{grid:{display:false},ticks:{color:'#f87171',font:{size:11}},position:'right'}}}
  });
}

function initStatusChart(apiData) {
  const labels = apiData ? apiData.map(d=>d.name) : ['Extinct','Ext.Wild','Crit.End.','Endangered','Vulnerable','Near Threat.','Least Concern'];
  const counts = apiData ? apiData.map(d=>d.count) : [4,2,31,58,87,41,25];
  const colors = apiData ? apiData.map(d=>d.color_hex||'#6b8f6b') : ['#1a1a2e','#4a0e0e','#dc2626','#ea580c','#d97706','#ca8a04','#16a34a'];
  new Chart(document.getElementById('statusChart'), {
    type:'doughnut',
    data:{labels,datasets:[{data:counts,backgroundColor:colors,borderWidth:0,hoverOffset:4}]},
    options:{responsive:true,maintainAspectRatio:false,cutout:'70%',plugins:{legend:{display:false},tooltip:CHART_OPTS.tooltip}}
  });
  const total = counts.reduce((a,b)=>a+b,0);
  document.getElementById('statusLegend').innerHTML = labels.map((l,i)=>`
    <div class="status-item">
      <div class="status-dot" style="background:${colors[i]}"></div>
      <span class="status-name">${l}</span>
      <span class="status-count">${counts[i]}</span>
      <span class="status-pct">${total?((counts[i]/total)*100).toFixed(0):0}%</span>
    </div>`).join('');
}

function initThreatPie() {
  new Chart(document.getElementById('threatPieChart'), {
    type:'doughnut',
    data:{labels:['Poaching','Habitat','Climate','Pollution','Trade'],
      datasets:[{data:[8,7,6,5,5],backgroundColor:['#f87171','#fb923c','#fbbf24','#60a5fa','#a78bfa'],borderWidth:0}]},
    options:{responsive:true,maintainAspectRatio:false,cutout:'60%',plugins:{legend:{display:false}}}
  });
}

function initThreatsCharts() {
  new Chart(document.getElementById('threatsBarChart'), {
    type:'bar',
    data:{labels:_threats.map(t=>t.name),
      datasets:[{label:'Affected',data:_threats.map(t=>t.affected_species||0),
        backgroundColor:['#f87171','#fb923c','#fbbf24','#60a5fa','#a78bfa','#c084fc','#34d399','#f472b6'],borderRadius:4,borderWidth:0}]},
    options:{responsive:true,maintainAspectRatio:false,indexAxis:'y',plugins:{legend:{display:false}},
      scales:{x:{grid:{color:CHART_OPTS.grid},ticks:{color:CHART_OPTS.color}},y:{grid:{color:CHART_OPTS.grid},ticks:{color:'#a5c8a5',font:{size:11}}}}}
  });
  const sevCounts = {critical:0,high:0,moderate:0,low:0};
  _threats.forEach(t => { sevCounts[t.severity]=(sevCounts[t.severity]||0)+1; });
  new Chart(document.getElementById('severityChart'), {
    type:'doughnut',
    data:{labels:['Critical','High','Moderate','Low'],
      datasets:[{data:[sevCounts.critical,sevCounts.high,sevCounts.moderate,sevCounts.low],
        backgroundColor:['#dc2626','#ea580c','#d97706','#16a34a'],borderWidth:0}]},
    options:{responsive:true,maintainAspectRatio:false,cutout:'60%',
      plugins:{legend:{labels:{color:'#a5c8a5',font:{size:11}},position:'bottom'},tooltip:CHART_OPTS.tooltip}}
  });
}

function renderThreatList() {
  const icons = {poaching:'#f87171',habitat_loss:'#fb923c',climate_change:'#fbbf24',pollution:'#60a5fa',illegal_trade:'#a78bfa'};
  const iconClass = {poaching:'fa-gun',habitat_loss:'fa-tree',climate_change:'fa-temperature-arrow-up',pollution:'fa-water',illegal_trade:'fa-money-bill'};
  const threats = _threats.length ? _threats : FB_THREATS;
  const maxAff = Math.max(...threats.map(t=>t.affected_species||t.affected||1));
  document.getElementById('threatList').innerHTML = threats.slice(0,5).map(t => {
    const color = icons[t.category]||'#6b8f6b';
    const ic    = iconClass[t.category]||'fa-triangle-exclamation';
    const aff   = t.affected_species || t.affected || 0;
    return `<div class="threat-item">
      <div class="threat-icon" style="background:${color}18;color:${color}"><i class="fa-solid ${ic}"></i></div>
      <div class="threat-info"><div class="threat-name">${escapeHTML(t.name)}</div><div class="threat-cat">${escapeHTML(t.category||'').replace('_',' ')}</div></div>
      <div style="width:80px;"><div class="pop-bar"><div class="pop-bar-fill" style="width:${(aff/maxAff*100).toFixed(0)}%;background:${color}"></div></div></div>
      <div class="threat-count">${aff} <span style="color:var(--text3);font-size:11px;">sp.</span></div>
    </div>`;
  }).join('');
}

function renderPagination(id, page, pages, cb) {
  const el = document.getElementById(id);
  if (!el || pages <= 1) { if(el) el.innerHTML=''; return; }
  let html = '';
  for (let i=1; i<=pages; i++) {
    html += `<button class="page-btn${i===page?' active':''}" onclick="(${cb.toString()})(${i})">${i}</button>`;
  }
  el.innerHTML = html;
}

document.addEventListener('DOMContentLoaded', async () => {
  const u = getUser();
  const initials = (u.username||'AD').substring(0,2).toUpperCase();
  document.getElementById('topAvatar').textContent    = initials;
  document.getElementById('sidebarAvatar').textContent = initials;
  document.getElementById('sidebarName').textContent  = escapeHTML(u.username) || 'Admin';
  document.getElementById('sidebarEmail').textContent = escapeHTML(u.email) || '';

  await loadSpeciesData();
  await loadDashboard();

  if (!_reports.length) _reports = FB_REPORTS;
  if (!_threats.length) _threats = FB_THREATS;
  if (!_locations.length) _locations = FB_LOCATIONS;
});

document.querySelector('.main')?.addEventListener('click', () => {
  if (window.innerWidth < 768) document.getElementById('sidebar').classList.remove('show');
});