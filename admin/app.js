import { initializeApp } from 'https://www.gstatic.com/firebasejs/10.14.1/firebase-app.js';
import {
  getAuth, onAuthStateChanged, signInWithEmailAndPassword, signOut,
} from 'https://www.gstatic.com/firebasejs/10.14.1/firebase-auth.js';
import {
  getFirestore, collection, query, where, orderBy, limit, onSnapshot, getCountFromServer,
  getDocs, doc, writeBatch, addDoc, updateDoc, serverTimestamp,
} from 'https://www.gstatic.com/firebasejs/10.14.1/firebase-firestore.js';
import { firebaseConfig, CITIES } from './config.js';

const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
const db = getFirestore(app);

const $ = (id) => document.getElementById(id);
const dateFmt = new Intl.DateTimeFormat('ar', { dateStyle: 'medium', timeStyle: 'short' });
const numFmt = new Intl.NumberFormat('ar');

/** ينشئ عنصراً بنص آمن (textContent فقط — بيانات المستخدمين لا تُحقن كـ HTML). */
function el(tag, { text, className, attrs } = {}, children = []) {
  const node = document.createElement(tag);
  if (text != null) node.textContent = text;
  if (className) node.className = className;
  if (attrs) for (const [k, v] of Object.entries(attrs)) node.setAttribute(k, v);
  for (const c of children) if (c) node.append(c);
  return node;
}

let toastTimer;
function toast(message) {
  const t = $('toast');
  t.textContent = message;
  t.hidden = false;
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => { t.hidden = true; }, 3500);
}

function confirmDialog(title, body, okLabel = 'تأكيد') {
  const dialog = $('confirm-dialog');
  $('confirm-title').textContent = title;
  $('confirm-body').textContent = body;
  $('confirm-ok').textContent = okLabel;
  dialog.returnValue = '';
  dialog.showModal();
  return new Promise((resolve) => {
    dialog.addEventListener('close', () => resolve(dialog.returnValue === 'ok'), { once: true });
  });
}

function friendlyError(e) {
  const code = e?.code ?? '';
  if (code.includes('invalid-credential') || code.includes('wrong-password') || code.includes('user-not-found')) {
    return 'البريد أو كلمة المرور غير صحيحة.';
  }
  if (code.includes('too-many-requests')) return 'محاولات كثيرة، حاول لاحقاً.';
  if (code.includes('permission-denied')) return 'لا تملك صلاحية لهذا الإجراء.';
  if (code.includes('network')) return 'تحقق من اتصال الإنترنت.';
  return e?.message ?? 'حدث خطأ غير متوقع.';
}

// ---------------------------------------------------------------------------
// المصادقة: لا يدخل إلا من لديه Custom Claim  admin: true
// ---------------------------------------------------------------------------

let unsubscribers = [];

function showView(view) {
  $('loading').hidden = true;
  $('login-view').hidden = view !== 'login';
  $('app-view').hidden = view !== 'app';
}

onAuthStateChanged(auth, async (user) => {
  unsubscribers.forEach((u) => u());
  unsubscribers = [];

  if (!user) {
    showView('login');
    return;
  }
  const token = await user.getIdTokenResult(true);
  if (token.claims.admin !== true) {
    showView('login');
    showLoginError('هذا الحساب لا يملك صلاحية الإدارة.');
    await signOut(auth);
    return;
  }
  $('admin-email').textContent = user.email ?? '';
  showView('app');
  startDashboard();
});

function showLoginError(message) {
  const e = $('login-error');
  e.textContent = message;
  e.hidden = false;
}

$('login-form').addEventListener('submit', async (ev) => {
  ev.preventDefault();
  $('login-error').hidden = true;
  const email = $('login-email').value.trim();
  const password = $('login-password').value;
  if (!email || !password) {
    showLoginError('أدخل البريد وكلمة المرور.');
    return;
  }
  const btn = $('login-submit');
  btn.disabled = true;
  try {
    await signInWithEmailAndPassword(auth, email, password);
  } catch (e) {
    showLoginError(friendlyError(e));
  } finally {
    btn.disabled = false;
  }
});

$('logout').addEventListener('click', () => signOut(auth));

// ---------------------------------------------------------------------------
// اللوحة
// ---------------------------------------------------------------------------

function startDashboard() {
  loadStats();
  unsubscribers.push(watchRequests());
  unsubscribers.push(watchHospitals());
}

$('refresh-stats').addEventListener('click', loadStats);

// ---------- الإحصاءات ----------

async function count(q) {
  const snap = await getCountFromServer(q);
  return snap.data().count;
}

async function loadStats() {
  const users = collection(db, 'users');
  const requests = collection(db, 'requests');
  const targets = {
    'stat-users': users,
    'stat-available': query(users, where('isAvailable', '==', true)),
    'stat-active': query(requests, where('status', '==', 'active')),
    'stat-completed': query(requests, where('status', '==', 'completed')),
  };
  await Promise.all(Object.entries(targets).map(async ([id, q]) => {
    try {
      $(id).textContent = numFmt.format(await count(q));
    } catch (e) {
      $(id).textContent = '!';
      console.error(id, e);
    }
  }));
}

// ---------- الطلبات ----------

let allRequests = [];

function watchRequests() {
  const q = query(collection(db, 'requests'), orderBy('createdAt', 'desc'), limit(200));
  return onSnapshot(q, (snap) => {
    allRequests = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
    renderRequests();
  }, (e) => toast(friendlyError(e)));
}

$('req-search').addEventListener('input', renderRequests);
$('req-status').addEventListener('change', renderRequests);

function renderRequests() {
  const term = $('req-search').value.trim().toLowerCase();
  const status = $('req-status').value;

  const rows = allRequests.filter((r) => {
    if (status !== 'all' && r.status !== status) return false;
    if (!term) return true;
    return [r.patientName, r.hospitalName, r.contactPhone]
      .some((v) => (v ?? '').toLowerCase().includes(term));
  });

  const body = $('requests-body');
  body.replaceChildren(...rows.map(requestRow));
  $('requests-empty').hidden = rows.length > 0;
}

function requestRow(r) {
  const active = r.status === 'active';
  const created = r.createdAt?.toDate ? dateFmt.format(r.createdAt.toDate()) : '—';

  const closeBtn = active
    ? el('button', { text: 'إغلاق', className: 'btn btn-sm', attrs: { type: 'button' } })
    : null;
  const deleteBtn = el('button', { text: 'حذف', className: 'btn btn-sm btn-danger', attrs: { type: 'button' } });
  closeBtn?.addEventListener('click', () => closeRequest(r));
  deleteBtn.addEventListener('click', () => deleteRequest(r));
  const actions = el('div', { className: 'actions' }, [closeBtn, deleteBtn]);

  return el('tr', {}, [
    el('td', { text: r.patientName ?? '', className: 'strong' }),
    el('td', { text: r.hospitalName ?? '' }),
    el('td', {}, [el('span', { text: r.bloodType ?? '', className: 'type-chip' })]),
    el('td', { text: r.scope === 'exact' ? 'الفصيلة فقط' : 'متوافقة' }),
    el('td', { text: `${numFmt.format(r.respondersCount ?? 0)} / ${numFmt.format(r.units ?? 0)}` }),
    el('td', {}, [el('span', { text: r.contactPhone ?? '', className: 'ltr' })]),
    el('td', { text: created }),
    el('td', {}, [el('span', { text: active ? 'نشط' : 'مكتمل', className: `pill ${active ? 'active' : 'completed'}` })]),
    el('td', {}, [actions]),
  ]);
}

async function closeRequest(r) {
  const ok = await confirmDialog('إغلاق الطلب؟', `سيختفي طلب «${r.patientName}» من قوائم المتبرعين.`, 'إغلاق');
  if (!ok) return;
  try {
    await updateDoc(doc(db, 'requests', r.id), { status: 'completed', completedAt: serverTimestamp() });
    toast('تم إغلاق الطلب.');
    loadStats();
  } catch (e) {
    toast(friendlyError(e));
  }
}

async function deleteRequest(r) {
  const ok = await confirmDialog(
    'حذف الطلب نهائياً؟',
    `سيُحذف طلب «${r.patientName}» وكل المستجيبين له. لا يمكن التراجع.`,
    'حذف',
  );
  if (!ok) return;
  try {
    // حذف المستجيبين أولاً (المجموعة الفرعية لا تُحذف تلقائياً مع المستند).
    const responders = await getDocs(collection(db, 'requests', r.id, 'responders'));
    const docs = responders.docs.map((d) => d.ref);
    for (let i = 0; i < docs.length; i += 450) {
      const batch = writeBatch(db);
      docs.slice(i, i + 450).forEach((ref) => batch.delete(ref));
      await batch.commit();
    }
    const batch = writeBatch(db);
    batch.delete(doc(db, 'requests', r.id));
    await batch.commit();
    toast('تم حذف الطلب.');
    loadStats();
  } catch (e) {
    toast(friendlyError(e));
  }
}

// ---------- المستشفيات ----------

let hospitals = [];
let editingId = null;

$('h-city').replaceChildren(...CITIES.map((c) => el('option', { text: c, attrs: { value: c } })));

function watchHospitals() {
  return onSnapshot(collection(db, 'hospitals'), (snap) => {
    hospitals = snap.docs
      .map((d) => ({ id: d.id, ...d.data() }))
      .sort((a, b) => (a.city ?? '').localeCompare(b.city ?? '', 'ar')
        || (a.order ?? 0) - (b.order ?? 0)
        || (a.name ?? '').localeCompare(b.name ?? '', 'ar'));
    renderHospitals();
  }, (e) => toast(friendlyError(e)));
}

$('hospital-form').addEventListener('submit', async (ev) => {
  ev.preventDefault();
  const name = $('h-name').value.trim();
  const city = $('h-city').value;
  if (name.length < 3) {
    toast('أدخل اسم المستشفى.');
    return;
  }
  if (hospitals.some((h) => h.city === city && (h.name ?? '').trim() === name)) {
    toast('هذا المستشفى مضاف مسبقاً.');
    return;
  }
  try {
    const order = Math.max(-1, ...hospitals.filter((h) => h.city === city).map((h) => h.order ?? 0)) + 1;
    await addDoc(collection(db, 'hospitals'), {
      name, city, isActive: true, order, createdAt: serverTimestamp(),
    });
    $('h-name').value = '';
    toast('تمت إضافة المستشفى.');
  } catch (e) {
    toast(friendlyError(e));
  }
});

function renderHospitals() {
  $('hospitals-list').replaceChildren(...hospitals.map(hospitalItem));
  $('hospitals-empty').hidden = hospitals.length > 0;
}

function hospitalItem(h) {
  const li = el('li', { className: h.isActive ? '' : 'inactive' });

  if (editingId === h.id) {
    const input = el('input', { attrs: { type: 'text', 'aria-label': 'اسم المستشفى' } });
    input.value = h.name ?? '';
    const save = el('button', { text: 'حفظ', className: 'btn btn-sm btn-primary', attrs: { type: 'button' } });
    const cancel = el('button', { text: 'إلغاء', className: 'btn btn-sm', attrs: { type: 'button' } });
    save.addEventListener('click', () => renameHospital(h, input.value));
    input.addEventListener('keydown', (e) => { if (e.key === 'Enter') renameHospital(h, input.value); });
    cancel.addEventListener('click', () => { editingId = null; renderHospitals(); });
    li.append(el('div', { className: 'edit-row' }, [input, save, cancel]));
    queueMicrotask(() => input.focus());
    return li;
  }

  const edit = el('button', { text: 'تعديل', className: 'btn btn-sm', attrs: { type: 'button' } });
  const toggle = el('button', {
    text: h.isActive ? 'إيقاف' : 'تفعيل',
    className: 'btn btn-sm',
    attrs: { type: 'button' },
  });
  edit.addEventListener('click', () => { editingId = h.id; renderHospitals(); });
  toggle.addEventListener('click', () => toggleHospital(h));

  li.append(
    el('div', { className: 'hospital-info' }, [
      el('strong', { text: h.name ?? '' }),
      el('span', { text: `${h.city ?? ''} · ${h.isActive ? 'ظاهر في التطبيق' : 'موقوف — لا يظهر في التطبيق'}` }),
    ]),
    el('div', { className: 'actions' }, [edit, toggle]),
  );
  return li;
}

async function renameHospital(h, value) {
  const name = value.trim();
  if (name.length < 3) {
    toast('الاسم قصير جداً.');
    return;
  }
  try {
    await updateDoc(doc(db, 'hospitals', h.id), { name });
    editingId = null;
    renderHospitals();
    toast('تم تحديث الاسم. الطلبات السابقة تحتفظ بالاسم القديم.');
  } catch (e) {
    toast(friendlyError(e));
  }
}

async function toggleHospital(h) {
  if (h.isActive) {
    const ok = await confirmDialog('إيقاف المستشفى؟', `لن يظهر «${h.name}» في قائمة إنشاء الطلبات.`, 'إيقاف');
    if (!ok) return;
  }
  try {
    await updateDoc(doc(db, 'hospitals', h.id), { isActive: !h.isActive });
  } catch (e) {
    toast(friendlyError(e));
  }
}

// تمييز رابط القسم الحالي في القائمة
const links = [...document.querySelectorAll('.nav-link')];
const observer = new IntersectionObserver((entries) => {
  for (const entry of entries) {
    if (!entry.isIntersecting) continue;
    links.forEach((a) => a.classList.toggle('active', a.getAttribute('href') === `#${entry.target.id}`));
  }
}, { rootMargin: '-40% 0px -55% 0px' });
['stats', 'requests', 'hospitals'].forEach((id) => observer.observe($(id)));
