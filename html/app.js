const resourceName = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'drs_vehcontrol';

const root = document.getElementById('veh-control');
const touchscreenShell = document.getElementById('touchscreen-shell');
const touchscreen = document.querySelector('.touchscreen');
const topStrip = document.querySelector('.top-strip');
const plate = document.getElementById('plate');
const plateNumber = document.getElementById('plate-number');
const statusText = document.getElementById('status');
const vehicleClass = document.getElementById('vehicle-class');
const fuel = document.getElementById('fuel');
const health = document.getElementById('health');
const settingsPanel = document.getElementById('settings-panel');
const accentSwatches = document.getElementById('accent-swatches');
const customAccent = document.getElementById('custom-accent');
const brightnessSlider = document.getElementById('ui-brightness');
const photoOverlaySlider = document.getElementById('photo-overlay');
const uiScaleSlider = document.getElementById('ui-scale');
const moveToggle = document.getElementById('move-toggle');
const resetPositionButton = document.getElementById('reset-position');
const closeButton = document.getElementById('close');
const fobRoot = document.getElementById('key-fob');
const fobShell = document.querySelector('.fob-shell');
const fobBrand = document.getElementById('fob-brand');
const fobScreen = document.querySelector('.fob-screen');
const fobBackButton = document.getElementById('fob-back');
const fobMoveButton = document.getElementById('fob-move');
const fobResizeButton = document.getElementById('fob-resize');
const fobTime = document.getElementById('fob-time');
const fobStatus = document.getElementById('fob-status');
const fobVehicle = document.getElementById('fob-vehicle');
const fobPlate = document.getElementById('fob-plate');
const fobRange = document.getElementById('fob-range');
const fobLockLabel = document.getElementById('fob-lock-label');
const fobEngineLabel = document.getElementById('fob-engine-label');
const fobTrunkLabel = document.getElementById('fob-trunk-label');
const fobWindowsLabel = document.getElementById('fob-windows-label');
const fobPanicLabel = document.getElementById('fob-panic-label');
const fobActionButtons = document.querySelectorAll('[data-fob-action]');

const grids = {
    vehicle: document.getElementById('vehicle-grid'),
    doors: document.getElementById('doors-grid'),
    windows: document.getElementById('windows-grid'),
    seats: document.getElementById('seats-grid'),
    utility: document.getElementById('utility-grid')
};

let state = {};
let fobState = {};
let locale = {};
let activeTab = 'vehicle';
let audioContext;
let moveMode = false;
let fobMoveMode = false;
let dragState;
let fobDragState;

const settingsKey = 'drs_vehcontrol_settings';
const defaultSettings = {
    accent: '',
    brightness: 100,
    photoOverlay: 82,
    scale: 1,
    position: {
        x: 0,
        y: 0
    },
    fob: {
        position: {
            x: 0,
            y: 0
        },
        scale: 1
    }
};

const fobScalePresets = [1.16, 1.08, 1, 0.94, 0.86, 0.78, 0.7, 0.62];

let uiSettings = loadSettings();

const icons = {
    engine: '<path d="M3 13h3l2-3h5l2 3h2v-2h3v8h-3v-2h-2l-2 3H8l-2-3H3z"/><path d="M9 7h5M11 7V4M7 10V8M19 13h2"/>',
    lock: '<rect x="5" y="10" width="14" height="10" rx="2"/><path d="M8 10V7a4 4 0 0 1 8 0v3"/><path d="M12 14v3"/>',
    unlock: '<rect x="5" y="10" width="14" height="10" rx="2"/><path d="M8 10V7a4 4 0 0 1 7.5-2"/><path d="M12 14v3"/>',
    radio: '<rect x="4" y="8" width="16" height="11" rx="2"/><path d="m8 8 8-4"/><circle cx="9" cy="14" r="2"/><path d="M14 13h3M14 16h3"/>',
    hazard: '<path d="M12 3 2.5 20h19z"/><path d="M12 9v5M12 17h.01"/>',
    interior: '<path d="M9 18h6"/><path d="M10 22h4"/><path d="M8.5 14.5a5 5 0 1 1 7 0c-.9.8-1.5 1.8-1.5 3h-4c0-1.2-.6-2.2-1.5-3z"/><path d="M12 2v2M4.9 4.9l1.4 1.4M19.1 4.9l-1.4 1.4M3 12h2M19 12h2"/>',
    door: '<path d="M8 3h8l2 18H8z"/><path d="M11 12h.01"/><path d="M8 3 5 6v12l3 3"/>',
    hood: '<path d="M5 15 8 5h8l3 10"/><path d="M4 15h16l-2 4H6z"/><path d="M9 9h6"/>',
    trunk: '<path d="M6 9h12l2 5v5H4v-5z"/><path d="M8 9V6h8v3"/><path d="M10 15h4"/>',
    window: '<path d="M6 4h12l1 14H5z"/><path d="M7 15h10"/><path d="m8 11 8-4"/>',
    windowsDown: '<path d="M5 4h14l-1 8H6z"/><path d="M8 16h8"/><path d="m9 20 3 2 3-2"/><path d="M12 14v8"/>',
    windowsUp: '<path d="M5 8h14l-1 10H6z"/><path d="M8 20h8"/><path d="m9 4 3-2 3 2"/><path d="M12 2v8"/>',
    seat: '<path d="M7 4h7a3 3 0 0 1 3 3v5h-6l-1 5H5V7a3 3 0 0 1 2-3z"/><path d="M11 12h8l1 6H10"/>',
    trailer: '<path d="M3 14h12v5H3z"/><path d="M15 16h3l3-3"/><circle cx="6" cy="20" r="1.5"/><circle cx="12" cy="20" r="1.5"/><path d="M5 14V9h6v5"/>',
    anchor: '<circle cx="12" cy="5" r="2"/><path d="M12 7v12M5 11h14"/><path d="M4 15a8 8 0 0 0 16 0"/><path d="m4 15-2 3M20 15l2 3"/>',
    landingGear: '<path d="M12 3v9M6 7l6 4 6-4"/><path d="m9 11-3 6M15 11l3 6"/><circle cx="6" cy="19" r="2"/><circle cx="18" cy="19" r="2"/>',
    autopilot: '<circle cx="12" cy="12" r="9"/><path d="m15.5 8.5-2.3 4.7-4.7 2.3 2.3-4.7z"/><path d="M12 3v2M12 19v2M3 12h2M19 12h2"/>',
    hover: '<path d="M3 7h18M7 7l5-4 5 4"/><path d="M12 7v6"/><path d="M8 13h8l-2 4h-4z"/><path d="M5 20h14"/>',
    roof: '<path d="M4 14h16l-2 5H6z"/><path d="M7 14c2-5 8-5 10 0"/><path d="M8 10 6 6M16 10l2-4"/>',
    cruise: '<path d="M5 18a8 8 0 1 1 14 0"/><path d="m12 12 4-3"/><path d="M8 18h8"/><path d="M7 8 5 6M17 8l2-2M12 6V3"/>',
    extra: '<path d="M12 3v18M3 12h18"/><path d="M5 5h4v4H5zM15 5h4v4h-4zM5 15h4v4H5zM15 15h4v4h-4z"/>',
    closeAll: '<path d="M5 5h14v14H5z"/><path d="m8 8 8 8M16 8l-8 8"/>',
    move: '<path d="M12 3v18M3 12h18"/><path d="m8 7 4-4 4 4M8 17l4 4 4-4M7 8l-4 4 4 4M17 8l4 4-4 4"/>',
    resize: '<path d="M4 14v6h6M20 10V4h-6"/><path d="M20 4 13 11M4 20l7-7"/>'
};

const iconAssets = {
    door: 'img/icons/doorFrontLeft.png',
    doorFrontLeft: 'img/icons/doorFrontLeft.png',
    doorFrontRight: 'img/icons/doorFrontRight.png',
    doorRearLeft: 'img/icons/doorRearLeft.png',
    doorRearRight: 'img/icons/doorRearRight.png',
    hood: 'img/icons/frontHood.png',
    trunk: 'img/icons/rearHood.png',
    window: 'img/icons/windowFrontLeft.png',
    windowFrontLeft: 'img/icons/windowFrontLeft.png',
    windowFrontRight: 'img/icons/windowFrontRight.png',
    windowRearLeft: 'img/icons/windowRearLeft.png',
    windowRearRight: 'img/icons/windowRearRight.png',
    windowsDown: 'img/icons/windowFrontLeft.png',
    windowsUp: 'img/icons/windowFrontLeft.png',
    seat: 'img/icons/seatFrontLeft.png'
};

const classArtwork = {
    default: { tint: 'rgba(79, 216, 255, 0.08)', image: 'img/classes/class_00_compacts.png' },
    0: { tint: 'rgba(79, 216, 255, 0.1)', image: 'img/classes/class_00_compacts.png' },
    1: { tint: 'rgba(84, 170, 255, 0.1)', image: 'img/classes/class_01_sedans.png' },
    2: { tint: 'rgba(57, 242, 167, 0.1)', image: 'img/classes/class_02_suvs.png' },
    3: { tint: 'rgba(77, 221, 255, 0.1)', image: 'img/classes/class_03_coupes.png' },
    4: { tint: 'rgba(255, 105, 67, 0.11)', image: 'img/classes/class_04_muscle.png' },
    5: { tint: 'rgba(255, 176, 46, 0.11)', image: 'img/classes/class_05_sports_classics.png' },
    6: { tint: 'rgba(77, 216, 255, 0.12)', image: 'img/classes/class_06_sports.png' },
    7: { tint: 'rgba(183, 124, 255, 0.12)', image: 'img/classes/class_07_super.png' },
    8: { tint: 'rgba(255, 176, 46, 0.1)', image: 'img/classes/class_08_motorcycles.png' },
    9: { tint: 'rgba(83, 255, 183, 0.1)', image: 'img/classes/class_09_offroad.png' },
    10: { tint: 'rgba(255, 176, 46, 0.1)', image: 'img/classes/class_10_industrial.png' },
    11: { tint: 'rgba(79, 216, 255, 0.09)', image: 'img/classes/class_11_utility.png' },
    12: { tint: 'rgba(84, 170, 255, 0.1)', image: 'img/classes/class_12_vans.png' },
    13: { tint: 'rgba(244, 251, 255, 0.09)', image: 'img/classes/class_13_cycles.png' },
    14: { tint: 'rgba(79, 216, 255, 0.11)', image: 'img/classes/class_14_boats.png' },
    15: { tint: 'rgba(57, 242, 167, 0.09)', image: 'img/classes/class_15_helicopters.png' },
    16: { tint: 'rgba(84, 170, 255, 0.09)', image: 'img/classes/class_16_planes.png' },
    17: { tint: 'rgba(244, 251, 255, 0.1)', image: 'img/classes/class_17_service.png' },
    18: { tint: 'rgba(255, 77, 95, 0.12)', image: 'img/classes/class_18_emergency.png' },
    19: { tint: 'rgba(113, 255, 142, 0.09)', image: 'img/classes/class_19_military.png' },
    20: { tint: 'rgba(255, 176, 46, 0.1)', image: 'img/classes/class_20_commercial.png' },
    21: { tint: 'rgba(244, 251, 255, 0.08)', image: 'img/classes/class_21_trains.png' },
    22: { tint: 'rgba(183, 124, 255, 0.11)', image: 'img/classes/class_22_open_wheel.png' }
};

const vehicleClassLabelStyles = {
    0: 'compacts',
    1: 'sedans',
    2: 'suvs',
    3: 'coupes',
    4: 'muscle',
    5: 'sports-classics',
    6: 'sports',
    7: 'super',
    8: 'motorcycles',
    9: 'off-road',
    10: 'industrial',
    11: 'utility',
    12: 'vans',
    13: 'cycles',
    14: 'boats',
    15: 'helicopters',
    16: 'planes',
    17: 'service',
    18: 'emergency',
    19: 'military',
    20: 'commercial',
    21: 'trains',
    22: 'open-wheel'
};

const fobCaseStyles = ['default', 'performance', 'luxury', 'rugged', 'fleet', 'tactical', 'moto', 'aero'];
const fobCaseStyleByClass = {
    0: 'default',
    1: 'luxury',
    2: 'luxury',
    3: 'performance',
    4: 'rugged',
    5: 'luxury',
    6: 'performance',
    7: 'performance',
    8: 'moto',
    9: 'rugged',
    10: 'fleet',
    11: 'fleet',
    12: 'fleet',
    13: 'moto',
    14: 'aero',
    15: 'aero',
    16: 'aero',
    17: 'fleet',
    18: 'tactical',
    19: 'tactical',
    20: 'fleet',
    21: 'fleet',
    22: 'performance'
};

const manufacturerStyleMap = {
    albany: 'luxury',
    annis: 'tuner',
    benefactor: 'euro',
    bf: 'utility',
    bollokan: 'euro',
    bravado: 'muscle',
    brute: 'industrial',
    buckingham: 'aero',
    canis: 'utility',
    cheval: 'muscle',
    coil: 'electric',
    declasse: 'muscle',
    dewbauchee: 'sport-luxury',
    dinka: 'tuner',
    dundreary: 'luxury',
    emperor: 'luxury',
    enus: 'ultra-luxury',
    fathom: 'utility',
    gallivanter: 'luxury',
    grotti: 'italian-sport',
    hijak: 'tuner',
    hvy: 'industrial',
    imponte: 'muscle',
    invetero: 'sport-luxury',
    jobuilt: 'industrial',
    karin: 'tuner',
    lampadati: 'italian-sport',
    lcc: 'moto',
    maibatsu: 'tuner',
    mammoth: 'military',
    mtl: 'industrial',
    nagasaki: 'moto',
    obey: 'euro',
    ocelot: 'sport-luxury',
    overflod: 'super',
    pegassi: 'italian-sport',
    pfister: 'sport-luxury',
    principe: 'moto',
    progen: 'super',
    rune: 'industrial',
    schyster: 'luxury',
    shitzu: 'moto',
    speedophile: 'marine',
    stanley: 'utility',
    truffade: 'super',
    ubermacht: 'euro',
    vapid: 'heritage',
    'vom-feuer': 'military',
    vomfeuer: 'military',
    vulcar: 'euro',
    weeny: 'compact',
    western: 'moto',
    willard: 'luxury',
    zirconium: 'utility'
};

function toStyleKey(value) {
    return String(value || '')
        .trim()
        .normalize('NFD')
        .replace(/[\u0300-\u036f]/g, '')
        .toLowerCase()
        .replace(/&/g, 'and')
        .replace(/[^a-z0-9]+/g, '-')
        .replace(/^-+|-+$/g, '');
}

function getLocaleValue(path) {
    return String(path || '')
        .split('.')
        .filter(Boolean)
        .reduce((current, key) => (current && typeof current === 'object' ? current[key] : undefined), locale);
}

function t(path, fallback = path, replacements = {}) {
    let value = getLocaleValue(path);

    if (typeof value !== 'string') {
        value = fallback;
    }

    Object.entries(replacements || {}).forEach(([key, replacement]) => {
        value = value.split(`{${key}}`).join(String(replacement));
    });

    return value;
}

function applyStaticLocale() {
    document.querySelectorAll('[data-locale]').forEach((target) => {
        target.textContent = t(target.dataset.locale, target.textContent);
    });

    document.querySelectorAll('[data-locale-aria]').forEach((target) => {
        target.setAttribute('aria-label', t(target.dataset.localeAria, target.getAttribute('aria-label') || ''));
    });

    document.querySelectorAll('[data-locale-title]').forEach((target) => {
        target.title = t(target.dataset.localeTitle, target.title || '');
    });

    applyFobLayout();
    setFobMoveMode(fobMoveMode);
}

function setLocale(nextLocale) {
    if (!nextLocale || typeof nextLocale !== 'object') {
        return;
    }

    locale = nextLocale;
    applyStaticLocale();
}

function renderFobBrand() {
    const makeName = String(fobState.makeName || '').trim();
    const makeKey = toStyleKey(makeName);
    const styleKey = manufacturerStyleMap[makeKey] || 'custom';
    const label = makeName || t('ui.smartKey', 'SMART KEY');
    const title = makeName
        ? t('ui.fob.brandTitle', `${makeName} key fob`, { make: makeName })
        : t('ui.fob.customBrandTitle', 'Custom vehicle key fob');

    fobBrand.textContent = label;
    fobBrand.title = title;
    fobBrand.setAttribute('aria-label', title);
    fobBrand.className = `fob-brand brand-${styleKey}`;

    if (makeKey) {
        fobBrand.classList.add(`make-${makeKey}`);
    }
}

async function post(action, data = {}) {
    try {
        const response = await fetch(`https://${resourceName}/${action}`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json; charset=UTF-8'
            },
            body: JSON.stringify(data)
        });

        let payload = null;

        try {
            payload = await response.json();
        } catch (error) {
            // Some close/ready callbacks may return no JSON body.
        }

        return {
            ok: response.ok && payload?.ok !== false,
            reason: payload?.reason || (response.ok ? null : 'request_failed')
        };
    } catch (error) {
        return { ok: false, reason: 'request_failed' };
    }
}

function loadSettings() {
    try {
        const stored = JSON.parse(localStorage.getItem(settingsKey));

        return {
            accent: stored?.accent || defaultSettings.accent,
            brightness: normalizeBrightness(stored?.brightness),
            photoOverlay: normalizePhotoOverlay(stored?.photoOverlay),
            scale: normalizeUiScale(stored?.scale),
            position: {
                x: Number(stored?.position?.x) || 0,
                y: Number(stored?.position?.y) || 0
            },
            fob: {
                position: {
                    x: Number(stored?.fob?.position?.x) || 0,
                    y: Number(stored?.fob?.position?.y) || 0
                },
                scale: normalizeFobScale(stored?.fob?.scale)
            }
        };
    } catch (error) {
        return {
            accent: defaultSettings.accent,
            brightness: defaultSettings.brightness,
            photoOverlay: defaultSettings.photoOverlay,
            scale: defaultSettings.scale,
            position: {
                x: defaultSettings.position.x,
                y: defaultSettings.position.y
            },
            fob: {
                position: {
                    x: defaultSettings.fob.position.x,
                    y: defaultSettings.fob.position.y
                },
                scale: defaultSettings.fob.scale
            }
        };
    }
}

function saveSettings() {
    try {
        localStorage.setItem(settingsKey, JSON.stringify(uiSettings));
    } catch (error) {
        // Settings persistence is optional; the live UI change still applies.
    }
}

function normalizeBrightness(value) {
    const next = Number(value);

    if (!Number.isFinite(next)) {
        return defaultSettings.brightness;
    }

    return Math.min(130, Math.max(70, Math.round(next)));
}

function normalizePhotoOverlay(value) {
    const next = Number(value);

    if (!Number.isFinite(next)) {
        return defaultSettings.photoOverlay;
    }

    return Math.min(95, Math.max(35, Math.round(next)));
}

function normalizeUiScale(value) {
    const next = Number(value);

    if (!Number.isFinite(next)) {
        return defaultSettings.scale;
    }

    const scale = next > 2 ? next / 100 : next;
    return Math.min(1, Math.max(0.65, Math.round(scale * 100) / 100));
}

function normalizeFobScale(value) {
    const next = Number(value);

    if (!Number.isFinite(next)) {
        return defaultSettings.fob.scale;
    }

    return Math.min(1.2, Math.max(0.62, Math.round(next * 100) / 100));
}

function getFobSettings() {
    if (!uiSettings.fob) {
        uiSettings.fob = {
            position: { ...defaultSettings.fob.position },
            scale: defaultSettings.fob.scale
        };
    }

    uiSettings.fob.position = uiSettings.fob.position || { ...defaultSettings.fob.position };
    uiSettings.fob.scale = normalizeFobScale(uiSettings.fob.scale);

    return uiSettings.fob;
}

function hexToRgb(hex) {
    const clean = hex.replace('#', '').trim();
    const value = clean.length === 3
        ? clean.split('').map((char) => char + char).join('')
        : clean;

    const parsed = Number.parseInt(value, 16);

    if (Number.isNaN(parsed)) {
        return [79, 216, 255];
    }

    return [
        (parsed >> 16) & 255,
        (parsed >> 8) & 255,
        parsed & 255
    ];
}

function applyAccent(hex) {
    const accent = hex || state.theme?.accent || '#4fd8ff';
    const [red, green, blue] = hexToRgb(accent);

    document.documentElement.style.setProperty('--accent', accent);
    document.documentElement.style.setProperty('--accent-rgb', `${red}, ${green}, ${blue}`);

    accentSwatches.querySelectorAll('.swatch').forEach((swatch) => {
        swatch.classList.toggle('active', swatch.dataset.accent.toLowerCase() === accent.toLowerCase());
    });

    customAccent.value = accent;
}

function applyBrightness(value = uiSettings.brightness) {
    const brightness = normalizeBrightness(value);

    uiSettings.brightness = brightness;
    document.documentElement.style.setProperty('--ui-brightness', (brightness / 100).toFixed(2));
    brightnessSlider.value = String(brightness);
}

function applyPhotoOverlay(value = uiSettings.photoOverlay) {
    const overlay = normalizePhotoOverlay(value);
    const edgeAlpha = overlay / 100;
    const centerAlpha = edgeAlpha * 0.61;
    const glassAlpha = 0.18 + edgeAlpha * 0.32;
    const fobTopAlpha = 0.38 + edgeAlpha * 0.37;
    const fobBottomAlpha = 0.54 + edgeAlpha * 0.44;
    const fobBaseTopAlpha = 0.72 + edgeAlpha * 0.24;
    const fobBaseBottomAlpha = 0.78 + edgeAlpha * 0.22;

    uiSettings.photoOverlay = overlay;
    document.documentElement.style.setProperty('--photo-edge-alpha', edgeAlpha.toFixed(2));
    document.documentElement.style.setProperty('--photo-center-alpha', centerAlpha.toFixed(2));
    document.documentElement.style.setProperty('--photo-glass-alpha', glassAlpha.toFixed(2));
    document.documentElement.style.setProperty('--fob-photo-top-alpha', fobTopAlpha.toFixed(2));
    document.documentElement.style.setProperty('--fob-photo-bottom-alpha', fobBottomAlpha.toFixed(2));
    document.documentElement.style.setProperty('--fob-photo-base-top-alpha', fobBaseTopAlpha.toFixed(2));
    document.documentElement.style.setProperty('--fob-photo-base-bottom-alpha', fobBaseBottomAlpha.toFixed(2));
    photoOverlaySlider.value = String(overlay);
}

function applyPosition() {
    root.style.setProperty('--menu-offset-x', `${uiSettings.position.x}px`);
    root.style.setProperty('--menu-offset-y', `${uiSettings.position.y}px`);
}

function applyUiScale(value = uiSettings.scale) {
    const scale = normalizeUiScale(value);

    uiSettings.scale = scale;
    root.style.setProperty('--ui-scale', scale.toFixed(2));
    uiScaleSlider.value = String(Math.round(scale * 100));
    uiScaleSlider.setAttribute('aria-valuetext', `${Math.round(scale * 100)}%`);
}

function applyFobLayout() {
    const settings = getFobSettings();

    fobRoot.style.setProperty('--fob-offset-x', `${settings.position.x}px`);
    fobRoot.style.setProperty('--fob-offset-y', `${settings.position.y}px`);
    fobRoot.style.setProperty('--fob-scale', settings.scale.toFixed(2));
    const resizeLabel = t('ui.fob.resizeWithScale', `Resize key fob (${Math.round(settings.scale * 100)}%)`, {
        scale: Math.round(settings.scale * 100)
    });

    fobResizeButton.title = resizeLabel;
    fobResizeButton.setAttribute('aria-label', resizeLabel);
}

function applyVehicleClassArt(classId) {
    const art = classArtwork[classId] || classArtwork.default;

    touchscreen.style.setProperty('--class-art', `url("${art.image}")`);
    touchscreen.style.setProperty('--class-tint', art.tint);
}

function applyTouchscreenFrame(config = {}) {
    const enabled = (config.enabled ?? config.Enabled) !== false;

    touchscreenShell.classList.toggle('frame-disabled', !enabled);
    touchscreenShell.dataset.frame = enabled ? 'enabled' : 'disabled';
}

function fitVehicleClassLabel() {
    vehicleClass.style.fontSize = '';

    const maximumSize = Number.parseFloat(window.getComputedStyle(vehicleClass).fontSize) || 11;
    const minimumSize = 7.5;
    let size = maximumSize;

    while (vehicleClass.scrollWidth > vehicleClass.clientWidth && size > minimumSize) {
        size -= 0.5;
        vehicleClass.style.fontSize = `${size}px`;
    }
}

function applyVehicleClassLabel(classId, label) {
    const style = vehicleClassLabelStyles[classId] || 'default';
    const className = `class-label class-label--${style}`;

    if (vehicleClass.className === className && vehicleClass.textContent === label) {
        return;
    }

    vehicleClass.className = className;
    vehicleClass.textContent = label;
    vehicleClass.title = label;
    fitVehicleClassLabel();
}

function applyFobVehicleClassArt(classId) {
    const hasClass = classId !== undefined && classId !== null && classId !== '';
    const art = hasClass ? classArtwork[classId] || classArtwork.default : null;

    fobScreen.style.setProperty('--fob-class-art', art ? `url("${art.image}")` : 'none');
    fobScreen.style.setProperty('--fob-class-tint', art ? art.tint : 'transparent');
}

function applyFobCaseStyle(classId) {
    const style = fobCaseStyleByClass[classId] || 'default';

    fobCaseStyles.forEach((caseStyle) => {
        fobRoot.classList.toggle(`case-${caseStyle}`, caseStyle === style);
    });
    fobRoot.dataset.caseStyle = style;
}

function getScaledBounds(element, scale, nextX, nextY) {
    const width = element.offsetWidth;
    const height = element.offsetHeight;
    const scaledWidth = width * scale;
    const scaledHeight = height * scale;
    const left = element.offsetLeft + (width - scaledWidth) / 2 + nextX;
    const top = element.offsetTop + height - scaledHeight + nextY;

    return {
        left,
        right: left + scaledWidth,
        top,
        bottom: top + scaledHeight
    };
}

function clampPosition(nextX, nextY) {
    const margin = 10;
    const bounds = getScaledBounds(touchscreenShell, normalizeUiScale(uiSettings.scale), nextX, nextY);
    let x = nextX;
    let y = nextY;

    if (bounds.left < margin) {
        x += margin - bounds.left;
    }

    if (bounds.right > window.innerWidth - margin) {
        x -= bounds.right - (window.innerWidth - margin);
    }

    if (bounds.top < margin) {
        y += margin - bounds.top;
    }

    if (bounds.bottom > window.innerHeight - margin) {
        y -= bounds.bottom - (window.innerHeight - margin);
    }

    return { x, y };
}

function clampFobPosition(nextX, nextY) {
    const margin = 10;
    const settings = getFobSettings();
    const bounds = getScaledBounds(fobRoot, settings.scale, nextX, nextY);
    let x = nextX;
    let y = nextY;

    if (bounds.left < margin) {
        x += margin - bounds.left;
    }

    if (bounds.right > window.innerWidth - margin) {
        x -= bounds.right - (window.innerWidth - margin);
    }

    if (bounds.top < margin) {
        y += margin - bounds.top;
    }

    if (bounds.bottom > window.innerHeight - margin) {
        y -= bounds.bottom - (window.innerHeight - margin);
    }

    return { x, y };
}

function setMoveMode(active) {
    moveMode = active;
    moveToggle.classList.toggle('active', moveMode);
    root.classList.toggle('move-mode', moveMode);
}

function setFobMoveMode(active) {
    fobMoveMode = active;
    fobMoveButton.classList.toggle('active', fobMoveMode);
    fobRoot.classList.toggle('move-mode', fobMoveMode);
    const moveLabel = fobMoveMode ? t('ui.fob.drag', 'Drag key fob') : t('ui.fob.move', 'Move key fob');
    fobMoveButton.title = moveLabel;
    fobMoveButton.setAttribute('aria-label', moveLabel);
}

function resetPosition() {
    uiSettings.position = { ...defaultSettings.position };
    saveSettings();
    applyPosition();
}

function cycleFobScale() {
    const settings = getFobSettings();
    let currentIndex = 0;
    let closestDistance = Number.POSITIVE_INFINITY;

    fobScalePresets.forEach((preset, index) => {
        const distance = Math.abs(preset - settings.scale);

        if (distance < closestDistance) {
            closestDistance = distance;
            currentIndex = index;
        }
    });

    settings.scale = fobScalePresets[(currentIndex + 1) % fobScalePresets.length];
    applyFobLayout();

    window.requestAnimationFrame(() => {
        settings.position = clampFobPosition(settings.position.x, settings.position.y);
        applyFobLayout();
        saveSettings();
    });
}

function tapSound() {
    try {
        audioContext = audioContext || new AudioContext();
        const osc = audioContext.createOscillator();
        const gain = audioContext.createGain();

        osc.frequency.value = 740;
        gain.gain.setValueAtTime(0.035, audioContext.currentTime);
        gain.gain.exponentialRampToValueAtTime(0.001, audioContext.currentTime + 0.045);
        osc.connect(gain);
        gain.connect(audioContext.destination);
        osc.start();
        osc.stop(audioContext.currentTime + 0.045);
    } catch (error) {
        // NUI can block audio context until user interaction; controls still work.
    }
}

function icon(name) {
    if (iconAssets[name]) {
        return `<span class="asset-icon" data-asset-icon="${name}" aria-hidden="true" style="--icon-url: url('${iconAssets[name]}')"></span>`;
    }

    return `<svg viewBox="0 0 24 24" aria-hidden="true">${icons[name] || icons.extra}</svg>`;
}

function hydrateInlineIcons() {
    document.querySelectorAll('[data-icon]').forEach((target) => {
        target.innerHTML = icon(target.dataset.icon);
    });
}

function bindButtonAction(button, onAction, pendingDelay = 160, disableWhilePending = false) {
    const activate = async () => {
        if (button.disabled || button.classList.contains('pending')) {
            return;
        }

        tapSound();
        button.classList.add('pending');

        if (disableWhilePending) {
            button.disabled = true;
        }

        try {
            await onAction();
        } finally {
            window.setTimeout(() => {
                button.classList.remove('pending');

                if (disableWhilePending) {
                    button.disabled = false;
                }
            }, pendingDelay);
        }
    };

    button.addEventListener('pointerdown', (event) => {
        if (!event.isPrimary || event.button !== 0) {
            return;
        }

        activate();
    });

    button.addEventListener('click', (event) => {
        // Pointer input is handled on pointerdown so a polling render cannot swallow it.
        if (event.detail !== 0) {
            return;
        }

        activate();
    });
}

function control(options) {
    const button = document.createElement('button');
    button.type = 'button';
    button.className = [
        'control',
        options.active ? 'active' : '',
        options.variant || '',
        options.disabled ? 'disabled' : ''
    ].filter(Boolean).join(' ');
    button.title = options.title || options.label;
    button.disabled = Boolean(options.disabled);
    button.innerHTML = `${icon(options.icon)}<span>${options.label}</span>`;

    if (options.onClick) {
        bindButtonAction(button, options.onClick, 160, true);
    }

    return button;
}

function setGrid(name, children) {
    const count = Math.max(children.length, 1);
    const rows = count > 6 ? 2 : 1;
    const cols = rows === 1 ? Math.max(5, count) : Math.ceil(count / rows);
    const grid = grids[name];

    grid.classList.toggle('dense', count > 6 && count <= 12);
    grid.classList.toggle('compact', count > 12);
    grid.style.setProperty('--grid-cols', cols);
    grid.style.setProperty('--grid-rows', rows);

    grid.replaceChildren(...children);
}

function empty(label) {
    const item = document.createElement('div');
    item.className = 'empty';
    item.textContent = label;
    return item;
}

function enabled(name) {
    return !state.enabled || state.enabled[name] !== false;
}

function renderVehicle() {
    const buttons = [];

    if (enabled('engine')) {
        buttons.push(control({
            label: state.engine ? t('ui.controls.engineOn', 'Engine On') : t('ui.controls.engineOff', 'Engine Off'),
            icon: 'engine',
            active: state.engine,
            onClick: () => post('toggleEngine')
        }));
    }

    if (enabled('locks')) {
        buttons.push(control({
            label: state.locked ? t('ui.controls.locked', 'Locked') : t('ui.controls.unlocked', 'Unlocked'),
            icon: state.locked ? 'lock' : 'unlock',
            active: state.locked,
            onClick: () => post('toggleLock')
        }));
    }

    if (enabled('autopilot') && state.autopilot?.supported) {
        const waypointActive = state.autopilot.active && state.autopilot.mode === 'waypoint';
        const autopilotLabel = !waypointActive
            ? t('ui.controls.autopilotStart', 'Start Autopilot')
            : (state.autopilot.phase === 'holding' || state.autopilot.phase === 'orbit')
                ? t('ui.controls.autopilotHolding', 'Autopilot Holding')
                : t('ui.controls.autopilotEnRoute', 'Autopilot En Route');

        buttons.push(control({
            label: autopilotLabel,
            icon: 'autopilot',
            active: waypointActive,
            onClick: () => post('toggleAutopilot')
        }));
    } else if (enabled('cruise') && state.cruise?.supported) {
        const cruiseSpeed = state.cruise.targetMph || 0;
        buttons.push(control({
            label: state.cruise.active
                ? t('ui.controls.cruiseActive', `Cruise ${cruiseSpeed}`, { speed: cruiseSpeed })
                : t('ui.controls.cruiseSet', 'Set Cruise'),
            icon: 'cruise',
            active: state.cruise.active,
            onClick: () => post('toggleCruise')
        }));
    }

    if (enabled('radio')) {
        buttons.push(control({
            label: state.radio ? t('ui.controls.radioOn', 'Radio On') : t('ui.controls.radioOff', 'Radio Off'),
            icon: 'radio',
            active: state.radio,
            onClick: () => post('toggleRadio')
        }));
    }

    if (enabled('hazards')) {
        buttons.push(control({
            label: t('ui.controls.hazards', 'Hazards'),
            icon: 'hazard',
            active: state.hazards,
            variant: 'danger',
            onClick: () => post('toggleHazards')
        }));
    }

    if (enabled('interiorLight')) {
        buttons.push(control({
            label: t('ui.controls.interiorLight', 'Interior Light'),
            icon: 'interior',
            active: state.interiorLight,
            onClick: () => post('toggleInteriorLight')
        }));
    }

    setGrid('vehicle', buttons.length ? buttons : [empty(t('ui.controls.noVehicleControls', 'Vehicle controls disabled'))]);
}

function doorIcon(id) {
    const doorId = Number(id);

    if (doorId === 0) return 'doorFrontLeft';
    if (doorId === 1) return 'doorFrontRight';
    if (doorId === 2) return 'doorRearLeft';
    if (doorId === 3) return 'doorRearRight';
    if (doorId === 4) return 'hood';
    if (doorId === 5) return 'trunk';
    return 'door';
}

function windowIcon(id) {
    const windowId = Number(id);

    if (windowId === 0) return 'windowFrontLeft';
    if (windowId === 1) return 'windowFrontRight';
    if (windowId === 2) return 'windowRearLeft';
    if (windowId === 3) return 'windowRearRight';
    return 'window';
}

function renderDoors() {
    const buttons = (state.doors || []).map((door) => control({
        label: door.label,
        icon: doorIcon(door.id),
        active: door.active,
        onClick: () => post('toggleDoor', { id: door.id })
    }));

    if (buttons.length && enabled('doors')) {
        buttons.push(control({
            label: t('ui.controls.closeAll', 'Close All'),
            icon: 'closeAll',
            onClick: () => post('closeAllDoors')
        }));
    }

    setGrid('doors', enabled('doors') && buttons.length ? buttons : [empty(t('ui.controls.noDoorControls', 'No door controls'))]);
}

function renderWindows() {
    const buttons = (state.windows || []).map((windowState) => control({
        label: windowState.label,
        icon: windowIcon(windowState.id),
        active: windowState.active,
        onClick: () => post('toggleWindow', { id: windowState.id })
    }));

    if (enabled('windows')) {
        buttons.push(control({
            label: t('ui.controls.allDown', 'All Down'),
            icon: 'windowsDown',
            onClick: () => post('allWindows', { down: true })
        }));
        buttons.push(control({
            label: t('ui.controls.allUp', 'All Up'),
            icon: 'windowsUp',
            onClick: () => post('allWindows', { down: false })
        }));
    }

    setGrid('windows', enabled('windows') ? buttons : [empty(t('ui.controls.noWindowControls', 'Window controls disabled'))]);
}

function renderSeats() {
    const buttons = (state.seats || []).map((seat) => control({
        label: seat.label,
        icon: 'seat',
        active: seat.active,
        disabled: seat.occupied,
        onClick: () => post('switchSeat', { id: seat.id })
    }));

    setGrid('seats', enabled('seats') && buttons.length ? buttons : [empty(t('ui.controls.noSeatControls', 'No seat controls'))]);
}

function renderUtility() {
    const buttons = [];

    if (enabled('autopilot')
        && state.autopilot?.supported
        && state.autopilot.aircraftType === 'helicopter') {
        const hoverActive = state.autopilot.active && state.autopilot.mode === 'hover';

        buttons.push(control({
            label: hoverActive
                ? t('ui.controls.hoverActive', 'Hovering')
                : t('ui.controls.hoverStart', 'Start Hover'),
            icon: 'hover',
            active: hoverActive,
            onClick: () => post('toggleHover')
        }));
    }

    if (enabled('anchor') && state.anchor && state.anchor.supported) {
        buttons.push(control({
            label: state.anchor.active
                ? t('ui.controls.anchorDown', 'Anchor Down')
                : t('ui.controls.anchorUp', 'Anchor Up'),
            icon: 'anchor',
            active: state.anchor.active,
            onClick: () => post('toggleAnchor')
        }));
    }

    if (enabled('landingGear') && state.landingGear && state.landingGear.supported) {
        const label = state.landingGear.broken
            ? t('ui.controls.gearBroken', 'Gear Broken')
            : state.landingGear.active
                ? t('ui.controls.gearDown', 'Gear Down')
                : t('ui.controls.gearUp', 'Gear Up');

        buttons.push(control({
            label,
            icon: 'landingGear',
            active: state.landingGear.active,
            disabled: state.landingGear.broken,
            onClick: () => post('toggleLandingGear')
        }));
    }

    if (enabled('trailer') && state.trailer) {
        buttons.push(control({
            label: t('ui.controls.detach', 'Detach'),
            icon: 'trailer',
            variant: 'warning',
            onClick: () => post('detachTrailer')
        }));
    }

    if (enabled('roof') && state.roof && state.roof.supported) {
        buttons.push(control({
            label: t('ui.controls.roof', 'Roof'),
            icon: 'roof',
            active: state.roof.active,
            onClick: () => post('toggleRoof')
        }));
    }

    if (enabled('extras')) {
        (state.extras || []).forEach((extra) => {
            buttons.push(control({
                label: extra.label,
                icon: 'extra',
                active: extra.active,
                onClick: () => post('toggleExtra', { id: extra.id })
            }));
        });
    }

    setGrid('utility', buttons.length ? buttons : [empty(t('ui.controls.noUtilityControls', 'No utility controls'))]);
}

function render() {
    setLocale(state.locale);

    if (!state.canUse) {
        return;
    }

    applyAccent(uiSettings.accent || state.theme?.accent || '#4fd8ff');
    applyBrightness();
    applyPhotoOverlay();
    document.documentElement.style.setProperty('--danger', state.theme?.danger || '#ff4d5f');
    document.documentElement.style.setProperty('--warning', state.theme?.warning || '#ffb02e');

    const plateText = (state.plate || 'DRS').trim();
    plateNumber.textContent = plateText;
    plate.title = `${t('ui.sanAndreas', 'San Andreas')} ${plateText}`;
    statusText.textContent = state.vehicleName || t('ui.vehicle', 'Vehicle');
    statusText.title = state.vehicleName || t('ui.vehicle', 'Vehicle');
    applyVehicleClassLabel(state.vehicleClass, state.vehicleClassName || t('ui.vehicle', 'Vehicle'));
    fuel.textContent = t('ui.fuel', `${state.fuel || 0}% FUEL`, { value: state.fuel || 0 });
    health.textContent = t('ui.engineHealth', `${state.engineHealth || 0}% ENG`, { value: state.engineHealth || 0 });
    applyTouchscreenFrame(state.interfaceFrame);
    applyVehicleClassArt(state.vehicleClass);

    renderVehicle();
    renderDoors();
    renderWindows();
    renderSeats();
    renderUtility();
}

function getFobActionButton(action) {
    return document.querySelector(`[data-fob-action="${action}"]`);
}

function fitFobButtonLabel(label) {
    const maximumSize = 10;
    const minimumSize = 7.5;
    let size = maximumSize;

    label.style.fontSize = `${maximumSize}px`;

    while (label.scrollWidth > label.clientWidth && size > minimumSize) {
        size -= 0.5;
        label.style.fontSize = `${size}px`;
    }
}

function fitFobButtonLabels() {
    fobActionButtons.forEach((button) => {
        const label = Array.from(button.children).find((child) => {
            return child.tagName === 'SPAN' && !child.classList.contains('fob-action-icon');
        });

        if (label) {
            fitFobButtonLabel(label);
        }
    });
}

function setFobButton(action, options) {
    const button = getFobActionButton(action);

    if (!button) {
        return;
    }

    button.disabled = Boolean(options.disabled);
    button.classList.toggle('active', Boolean(options.active));
    button.title = options.title || options.label;

    const iconTarget = button.querySelector('.fob-action-icon');
    if (iconTarget && options.icon && iconTarget.dataset.iconName !== options.icon) {
        iconTarget.innerHTML = icon(options.icon);
        iconTarget.dataset.iconName = options.icon;
    }

    const label = Array.from(button.children).find((child) => {
        return child.tagName === 'SPAN' && !child.classList.contains('fob-action-icon');
    });

    if (label && label.textContent !== options.label) {
        label.textContent = options.label;
        fitFobButtonLabel(label);
    }
}

function fitFobStatus() {
    const maximumSize = 16;
    const minimumSize = 10;
    let size = maximumSize;

    fobStatus.style.fontSize = `${maximumSize}px`;

    while (fobStatus.scrollWidth > fobStatus.clientWidth && size > minimumSize) {
        size -= 0.5;
        fobStatus.style.fontSize = `${size}px`;
    }
}

function renderFob() {
    setLocale(fobState.locale);

    const canUse = fobState.canUse === true;
    const message = (fobState.message || (canUse ? t('ui.fob.ready', 'READY') : t('ui.fob.noSignal', 'NO SIGNAL'))).toUpperCase();
    const distance = Number.isFinite(Number(fobState.distance)) ? `${Math.round(Number(fobState.distance))}M` : '--M';

    applyAccent(uiSettings.accent || fobState.theme?.accent || state.theme?.accent || '#4fd8ff');
    applyBrightness();
    document.documentElement.style.setProperty('--danger', fobState.theme?.danger || state.theme?.danger || '#ff4d5f');
    document.documentElement.style.setProperty('--warning', fobState.theme?.warning || state.theme?.warning || '#ffb02e');

    fobRoot.classList.toggle('no-signal', !canUse);
    renderFobBrand();
    applyFobVehicleClassArt(fobState.vehicleClass);
    applyFobCaseStyle(fobState.vehicleClass);
    fobStatus.textContent = message;
    fobStatus.title = message;
    fitFobStatus();
    const fobDisplayVehicle = fobState.modelName || fobState.vehicleName || t('ui.noVehicle', 'NO VEHICLE');
    fobVehicle.textContent = fobDisplayVehicle;
    fobVehicle.title = fobDisplayVehicle;
    fobPlate.textContent = (fobState.plate || '---').trim();
    fobRange.textContent = distance;

    const locked = fobState.locked === true;
    const engine = fobState.engine === true;
    const trunk = fobState.trunk === true;
    const windowsDown = fobState.windowsDown === true;
    const panic = fobState.panic === true;
    const actions = fobState.actions || {};

    fobLockLabel.textContent = locked ? t('ui.fob.unlock', 'UNLOCK') : t('ui.fob.lock', 'LOCK');
    fobEngineLabel.textContent = engine ? t('ui.fob.stop', 'STOP') : t('ui.fob.start', 'START');
    fobTrunkLabel.textContent = trunk ? t('ui.fob.closeAction', 'CLOSE') : t('ui.fob.trunk', 'TRUNK');
    fobWindowsLabel.textContent = t('ui.fob.windows', 'WINDOWS');
    fobPanicLabel.textContent = t('ui.fob.panic', 'PANIC');

    setFobButton('lock', {
        label: locked ? t('ui.fob.unlock', 'UNLOCK') : t('ui.fob.lock', 'LOCK'),
        icon: locked ? 'unlock' : 'lock',
        active: locked,
        disabled: !canUse || actions.locks === false
    });
    setFobButton('engine', {
        label: engine ? t('ui.fob.stop', 'STOP') : t('ui.fob.start', 'START'),
        icon: 'engine',
        active: engine,
        disabled: !canUse || actions.engine === false
    });
    setFobButton('trunk', {
        label: trunk ? t('ui.fob.closeAction', 'CLOSE') : t('ui.fob.trunk', 'TRUNK'),
        icon: 'trunk',
        active: trunk,
        disabled: !canUse || actions.trunk === false || fobState.hasTrunk === false
    });
    setFobButton('windows', {
        label: t('ui.fob.windows', 'WINDOWS'),
        icon: windowsDown ? 'windowsUp' : 'windowsDown',
        active: windowsDown,
        disabled: !canUse || actions.windows === false
    });
    setFobButton('panic', {
        label: t('ui.fob.panic', 'PANIC'),
        active: panic,
        disabled: !canUse || actions.panic === false
    });
}

function updateFobClock() {
    const now = new Date();
    fobTime.textContent = now.toLocaleTimeString([], {
        hour: '2-digit',
        minute: '2-digit',
        hour12: false
    });
}

function setTab(tabName) {
    activeTab = tabName;
    settingsPanel.setAttribute('aria-hidden', String(activeTab !== 'settings'));

    document.querySelectorAll('.tab').forEach((tab) => {
        tab.classList.toggle('active', tab.dataset.tab === activeTab);
    });

    document.querySelectorAll('.panel').forEach((panel) => {
        panel.classList.toggle('active', panel.dataset.panel === activeTab);
    });

    if (activeTab !== 'settings') {
        setMoveMode(false);
    }
}

document.querySelectorAll('.tab').forEach((tab) => {
    tab.addEventListener('click', () => {
        tapSound();
        setTab(tab.dataset.tab);
    });
});

moveToggle.addEventListener('click', () => {
    tapSound();
    setMoveMode(!moveMode);
});

resetPositionButton.addEventListener('click', () => {
    tapSound();
    resetPosition();
});

accentSwatches.querySelectorAll('.swatch').forEach((swatch) => {
    swatch.addEventListener('click', () => {
        tapSound();
        uiSettings.accent = swatch.dataset.accent;
        saveSettings();
        applyAccent(uiSettings.accent);
    });
});

customAccent.addEventListener('input', () => {
    uiSettings.accent = customAccent.value;
    saveSettings();
    applyAccent(uiSettings.accent);
});

brightnessSlider.addEventListener('input', () => {
    uiSettings.brightness = normalizeBrightness(brightnessSlider.value);
    saveSettings();
    applyBrightness();
});

photoOverlaySlider.addEventListener('input', () => {
    uiSettings.photoOverlay = normalizePhotoOverlay(photoOverlaySlider.value);
    saveSettings();
    applyPhotoOverlay();
});

uiScaleSlider.addEventListener('input', () => {
    uiSettings.scale = normalizeUiScale(uiScaleSlider.value);
    applyUiScale();

    window.requestAnimationFrame(() => {
        uiSettings.position = clampPosition(uiSettings.position.x, uiSettings.position.y);
        applyPosition();
        saveSettings();
    });
});

topStrip.addEventListener('pointerdown', (event) => {
    if (!moveMode || event.target.closest('button')) {
        return;
    }

    dragState = {
        pointerId: event.pointerId,
        startX: event.clientX,
        startY: event.clientY,
        originX: uiSettings.position.x,
        originY: uiSettings.position.y
    };

    topStrip.setPointerCapture(event.pointerId);
    event.preventDefault();
});

topStrip.addEventListener('pointermove', (event) => {
    if (!dragState || event.pointerId !== dragState.pointerId) {
        return;
    }

    const next = clampPosition(
        dragState.originX + event.clientX - dragState.startX,
        dragState.originY + event.clientY - dragState.startY
    );

    uiSettings.position = next;
    applyPosition();
});

function finishDrag(event) {
    if (!dragState || event.pointerId !== dragState.pointerId) {
        return;
    }

    dragState = null;
    saveSettings();
}

topStrip.addEventListener('pointerup', finishDrag);
topStrip.addEventListener('pointercancel', finishDrag);

closeButton.addEventListener('click', () => {
    tapSound();
    post('close');
});

fobBackButton.addEventListener('click', () => {
    tapSound();
    post('close');
});

fobMoveButton.addEventListener('click', () => {
    tapSound();
    setFobMoveMode(!fobMoveMode);
});

fobResizeButton.addEventListener('click', () => {
    tapSound();
    setFobMoveMode(false);
    cycleFobScale();
});

fobActionButtons.forEach((button) => {
    bindButtonAction(
        button,
        () => post('keyFobAction', { action: button.dataset.fobAction }),
        180
    );
});

fobShell.addEventListener('pointerdown', (event) => {
    if (!fobMoveMode || event.target.closest('button')) {
        return;
    }

    const settings = getFobSettings();

    fobDragState = {
        pointerId: event.pointerId,
        startX: event.clientX,
        startY: event.clientY,
        originX: settings.position.x,
        originY: settings.position.y
    };

    fobShell.setPointerCapture(event.pointerId);
    event.preventDefault();
});

fobShell.addEventListener('pointermove', (event) => {
    if (!fobDragState || event.pointerId !== fobDragState.pointerId) {
        return;
    }

    const settings = getFobSettings();

    settings.position = clampFobPosition(
        fobDragState.originX + event.clientX - fobDragState.startX,
        fobDragState.originY + event.clientY - fobDragState.startY
    );

    applyFobLayout();
});

function finishFobDrag(event) {
    if (!fobDragState || event.pointerId !== fobDragState.pointerId) {
        return;
    }

    fobDragState = null;
    saveSettings();
}

fobShell.addEventListener('pointerup', finishFobDrag);
fobShell.addEventListener('pointercancel', finishFobDrag);

window.addEventListener('keydown', (event) => {
    if (event.key === 'Escape') {
        event.preventDefault();
        event.stopPropagation();
        event.stopImmediatePropagation();
        post('close');
    }
});

window.addEventListener('message', (event) => {
    const message = event.data || {};

    if (message.action === 'locale') {
        setLocale(message.data);
    }

    if (message.action === 'open') {
        root.classList.add('visible');
        root.setAttribute('aria-hidden', 'false');
        fobRoot.classList.remove('visible');
        fobRoot.setAttribute('aria-hidden', 'true');
    }

    if (message.action === 'close') {
        root.classList.remove('visible');
        root.setAttribute('aria-hidden', 'true');
    }

    if (message.action === 'state') {
        state = message.data || {};
        render();
    }

    if (message.action === 'fobOpen') {
        fobRoot.classList.add('visible');
        fobRoot.setAttribute('aria-hidden', 'false');
        root.classList.remove('visible');
        root.setAttribute('aria-hidden', 'true');
        updateFobClock();
    }

    if (message.action === 'fobClose') {
        fobRoot.classList.remove('visible');
        fobRoot.setAttribute('aria-hidden', 'true');
        setFobMoveMode(false);
    }

    if (message.action === 'fobState') {
        fobState = message.data || {};
        renderFob();
    }

    if (message.action === 'unavailable') {
        root.classList.remove('visible');
        root.setAttribute('aria-hidden', 'true');
        setFobMoveMode(false);
    }
});

window.addEventListener('resize', () => {
    const settings = getFobSettings();

    uiSettings.position = clampPosition(uiSettings.position.x, uiSettings.position.y);
    settings.position = clampFobPosition(settings.position.x, settings.position.y);
    applyPosition();
    applyFobLayout();
    fitVehicleClassLabel();
    fitFobStatus();
    fitFobButtonLabels();
    saveSettings();
});

post('ready');
hydrateInlineIcons();
applyStaticLocale();
updateFobClock();
window.setInterval(updateFobClock, 10000);
applyPosition();
applyUiScale();
applyFobLayout();
applyAccent(uiSettings.accent || '#4fd8ff');
applyBrightness();
applyPhotoOverlay();
applyTouchscreenFrame();
applyVehicleClassArt('default');

if (document.fonts) {
    document.fonts.ready.then(() => {
        fitVehicleClassLabel();
        fitFobStatus();
        fitFobButtonLabels();
    });
}
