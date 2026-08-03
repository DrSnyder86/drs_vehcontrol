const fs = require('fs');
const path = require('path');
const zlib = require('zlib');

const outDir = path.join(__dirname, '..', 'html', 'img', 'fob_frames');
const W = 444;
const H = 772;

function clamp(value, min = 0, max = 1) {
    return Math.max(min, Math.min(max, value));
}

function rgba(r, g, b, a = 255) {
    return [r, g, b, a];
}

function mix(a, b, t) {
    return a + (b - a) * t;
}

function mixColor(a, b, t) {
    return [
        mix(a[0], b[0], t),
        mix(a[1], b[1], t),
        mix(a[2], b[2], t),
        mix(a[3] ?? 255, b[3] ?? 255, t)
    ];
}

function hashNoise(x, y, seed) {
    let n = Math.imul(x + seed * 374761393, 668265263) ^ Math.imul(y + seed * 1442695041, 2246822519);
    n = Math.imul(n ^ (n >>> 13), 1274126177);
    return ((n ^ (n >>> 16)) >>> 0) / 4294967295;
}

function blend(data, x, y, color, alpha = 1) {
    if (x < 0 || y < 0 || x >= W || y >= H) return;

    const idx = (Math.floor(y) * W + Math.floor(x)) * 4;
    const srcA = clamp((color[3] / 255) * alpha);
    const dstA = data[idx + 3] / 255;
    const outA = srcA + dstA * (1 - srcA);

    if (outA <= 0) return;

    data[idx] = Math.round((color[0] * srcA + data[idx] * dstA * (1 - srcA)) / outA);
    data[idx + 1] = Math.round((color[1] * srcA + data[idx + 1] * dstA * (1 - srcA)) / outA);
    data[idx + 2] = Math.round((color[2] * srcA + data[idx + 2] * dstA * (1 - srcA)) / outA);
    data[idx + 3] = Math.round(outA * 255);
}

function drawCircle(data, cx, cy, r, color, alpha = 1) {
    const minX = Math.floor(cx - r);
    const maxX = Math.ceil(cx + r);
    const minY = Math.floor(cy - r);
    const maxY = Math.ceil(cy + r);

    for (let y = minY; y <= maxY; y++) {
        for (let x = minX; x <= maxX; x++) {
            const d = Math.hypot(x - cx, y - cy);

            if (d <= r) {
                blend(data, x, y, color, alpha * clamp((r - d) / 1.7));
            }
        }
    }
}

function drawRect(data, x, y, w, h, color, alpha = 1) {
    for (let yy = Math.floor(y); yy < Math.ceil(y + h); yy++) {
        for (let xx = Math.floor(x); xx < Math.ceil(x + w); xx++) {
            blend(data, xx, yy, color, alpha);
        }
    }
}

function pointInPolygon(x, y, points) {
    let inside = false;

    for (let i = 0, j = points.length - 1; i < points.length; j = i++) {
        const xi = points[i][0];
        const yi = points[i][1];
        const xj = points[j][0];
        const yj = points[j][1];
        const intersect = yi > y !== yj > y && x < ((xj - xi) * (y - yi)) / (yj - yi) + xi;

        if (intersect) inside = !inside;
    }

    return inside;
}

function distanceToSegment(px, py, ax, ay, bx, by) {
    const dx = bx - ax;
    const dy = by - ay;
    const lenSq = dx * dx + dy * dy;
    const t = lenSq === 0 ? 0 : clamp(((px - ax) * dx + (py - ay) * dy) / lenSq);
    const x = ax + t * dx;
    const y = ay + t * dy;

    return Math.hypot(px - x, py - y);
}

function distanceToPolygon(x, y, points) {
    let distance = Infinity;

    for (let i = 0; i < points.length; i++) {
        const a = points[i];
        const b = points[(i + 1) % points.length];
        distance = Math.min(distance, distanceToSegment(x, y, a[0], a[1], b[0], b[1]));
    }

    return distance;
}

function roundedRectMask(x, y, rect) {
    const { x: rx, y: ry, w, h, r } = rect;
    const qx = Math.abs(x - (rx + w / 2)) - (w / 2 - r);
    const qy = Math.abs(y - (ry + h / 2)) - (h / 2 - r);
    const outside = Math.hypot(Math.max(qx, 0), Math.max(qy, 0)) + Math.min(Math.max(qx, qy), 0) - r;

    return { inside: outside <= 0, edge: Math.abs(outside) };
}

function polygonMask(x, y, points) {
    return {
        inside: pointInPolygon(x, y, points),
        edge: distanceToPolygon(x, y, points)
    };
}

function lineDetail(data, x, y, w, h, color, alpha = 1) {
    drawRect(data, x, y, w, h, color, alpha);
}

function drawFrame(style) {
    const data = Buffer.alloc(W * H * 4);
    const accentData = Buffer.alloc(W * H * 4);
    const mask = style.mask;
    const seed = style.seed;

    for (let y = 0; y < H; y++) {
        for (let x = 0; x < W; x++) {
            const m = mask(x, y);

            if (!m.inside) continue;

            const nx = x / W;
            const ny = y / H;
            const side = Math.abs(nx - 0.5) * 2;
            const vertical = ny;
            const edgeShade = clamp(1 - m.edge / 82);
            const topLight = clamp(1 - vertical * 1.45) * 0.12;
            const bottomShade = clamp((vertical - 0.56) / 0.44) * 0.34;
            const sideShade = side * 0.35;
            const diagonal = clamp(1 - Math.abs(nx + ny * 0.56 - 0.55) / 0.1) * style.diagonal * 0.54;
            const noise = (hashNoise(x, y, seed) - 0.5) * style.noise;
            const t = clamp(vertical * 0.74 + side * 0.18);
            let color = mixColor(style.top, style.bottom, t);
            const light = topLight + diagonal + noise - bottomShade - sideShade - edgeShade * 0.22;

            color[0] = clamp(color[0] + light * 255, 0, 255);
            color[1] = clamp(color[1] + light * 255, 0, 255);
            color[2] = clamp(color[2] + light * 255, 0, 255);
            color[3] = clamp(m.edge / 2.8) * 255;
            const idx = (y * W + x) * 4;

            if (m.edge < style.border) {
                color = mixColor(color, style.borderColor, 0.82);
                color[3] = 255;

                accentData[idx] = 255;
                accentData[idx + 1] = 255;
                accentData[idx + 2] = 255;
                accentData[idx + 3] = style.borderAccentAlpha ?? 255;
            }

            data[idx] = Math.round(color[0]);
            data[idx + 1] = Math.round(color[1]);
            data[idx + 2] = Math.round(color[2]);
            data[idx + 3] = Math.round(color[3]);
        }
    }

    for (const detail of style.details || []) {
        detail(data);
    }

    for (const detail of style.accentDetails || []) {
        detail(accentData);
    }

    writePng(path.join(outDir, style.file), W, H, data);
    writePng(path.join(outDir, style.file.replace('.png', '_accent.png')), W, H, accentData);
}

function writePng(file, width, height, rgbaData) {
    const scanline = width * 4 + 1;
    const raw = Buffer.alloc(scanline * height);

    for (let y = 0; y < height; y++) {
        raw[y * scanline] = 0;
        rgbaData.copy(raw, y * scanline + 1, y * width * 4, (y + 1) * width * 4);
    }

    const chunks = [
        pngChunk('IHDR', Buffer.concat([
            u32(width),
            u32(height),
            Buffer.from([8, 6, 0, 0, 0])
        ])),
        pngChunk('IDAT', zlib.deflateSync(raw, { level: 9 })),
        pngChunk('IEND', Buffer.alloc(0))
    ];

    fs.mkdirSync(path.dirname(file), { recursive: true });
    fs.writeFileSync(file, Buffer.concat([Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]), ...chunks]));
}

function u32(value) {
    const buffer = Buffer.alloc(4);
    buffer.writeUInt32BE(value >>> 0);
    return buffer;
}

function crc32(buffer) {
    let crc = ~0;

    for (let i = 0; i < buffer.length; i++) {
        crc ^= buffer[i];
        for (let j = 0; j < 8; j++) {
            crc = (crc >>> 1) ^ (0xedb88320 & -(crc & 1));
        }
    }

    return ~crc >>> 0;
}

function pngChunk(type, data) {
    const typeBuffer = Buffer.from(type);
    const crcBuffer = u32(crc32(Buffer.concat([typeBuffer, data])));

    return Buffer.concat([u32(data.length), typeBuffer, data, crcBuffer]);
}

const rounded = (x, y, w, h, r) => (px, py) => roundedRectMask(px, py, { x, y, w, h, r });
const poly = (points) => (px, py) => polygonMask(px, py, points);

const frames = [
    {
        file: 'fob_default.png',
        seed: 3,
        mask: rounded(40, 8, 364, 748, 66),
        top: rgba(37, 48, 52),
        bottom: rgba(6, 9, 11),
        borderColor: rgba(154, 166, 171),
        border: 3.2,
        diagonal: 0.11,
        noise: 0.07,
        accentDetails: [
            (d) => lineDetail(d, 82, 48, 280, 2, rgba(255, 255, 255, 90), 0.42),
            (d) => lineDetail(d, 74, 716, 296, 2, rgba(255, 255, 255, 70), 0.24)
        ]
    },
    {
        file: 'fob_performance.png',
        seed: 7,
        mask: poly([[70, 0], [374, 0], [432, 72], [420, 670], [360, 772], [84, 772], [24, 670], [12, 72]]),
        top: rgba(34, 41, 45),
        bottom: rgba(2, 4, 6),
        borderColor: rgba(142, 151, 156),
        border: 4.2,
        diagonal: 0.2,
        noise: 0.09,
        details: [
            (d) => {
                for (let y = 24; y < 744; y += 14) {
                    lineDetail(d, 96, y, 252, 1, rgba(255, 255, 255, 32), 0.25);
                }
            }
        ],
        accentDetails: [
            (d) => lineDetail(d, 54, 70, 12, 610, rgba(255, 255, 255, 180), 0.48),
            (d) => lineDetail(d, 378, 70, 12, 610, rgba(255, 255, 255, 170), 0.34)
        ]
    },
    {
        file: 'fob_luxury.png',
        seed: 11,
        mask: rounded(24, 4, 396, 758, 88),
        top: rgba(51, 61, 65),
        bottom: rgba(8, 8, 8),
        borderColor: rgba(165, 165, 160),
        border: 3.6,
        diagonal: 0.14,
        noise: 0.045,
        accentDetails: [
            (d) => lineDetail(d, 54, 62, 7, 626, rgba(255, 255, 255, 210), 0.58),
            (d) => lineDetail(d, 383, 62, 7, 626, rgba(255, 255, 255, 180), 0.46),
            (d) => lineDetail(d, 102, 42, 240, 2, rgba(255, 255, 255, 150), 0.38),
            (d) => lineDetail(d, 102, 722, 240, 2, rgba(255, 255, 255, 100), 0.22)
        ]
    },
    {
        file: 'fob_rugged.png',
        seed: 17,
        mask: poly([[58, 0], [386, 0], [444, 52], [444, 720], [386, 772], [58, 772], [0, 720], [0, 52]]),
        top: rgba(52, 54, 53),
        bottom: rgba(7, 8, 8),
        borderColor: rgba(169, 172, 172),
        border: 5,
        diagonal: 0.08,
        noise: 0.11,
        details: [
            (d) => [46, 398].forEach((x) => {
                drawCircle(d, x, 42, 8, rgba(226, 228, 228, 210), 0.8);
                drawCircle(d, x, 730, 8, rgba(226, 228, 228, 180), 0.68);
            }),
            (d) => {
                for (let y = 88; y < 690; y += 24) {
                    lineDetail(d, 18, y, 28, 3, rgba(0, 0, 0, 120), 0.45);
                    lineDetail(d, 398, y, 28, 3, rgba(0, 0, 0, 120), 0.45);
                }
            }
        ]
    },
    {
        file: 'fob_fleet.png',
        seed: 23,
        mask: rounded(18, 6, 408, 756, 30),
        top: rgba(39, 50, 54),
        bottom: rgba(7, 10, 11),
        borderColor: rgba(156, 165, 168),
        border: 3.4,
        diagonal: 0.07,
        noise: 0.07,
        details: [
            (d) => {
                for (let y = 66; y < 704; y += 32) {
                    lineDetail(d, 58, y, 328, 1, rgba(255, 255, 255, 35), 0.22);
                }
            }
        ],
        accentDetails: [
            (d) => lineDetail(d, 36, 42, 14, 662, rgba(255, 255, 255, 210), 0.5),
            (d) => lineDetail(d, 394, 42, 14, 662, rgba(255, 255, 255, 170), 0.36),
            (d) => lineDetail(d, 74, 48, 296, 3, rgba(255, 255, 255, 170), 0.26)
        ]
    },
    {
        file: 'fob_tactical.png',
        seed: 31,
        mask: poly([[50, 0], [394, 0], [444, 42], [444, 282], [424, 326], [424, 446], [444, 490], [444, 730], [392, 772], [52, 772], [0, 730], [0, 490], [20, 446], [20, 326], [0, 282], [0, 42]]),
        top: rgba(47, 49, 49),
        bottom: rgba(5, 6, 6),
        borderColor: rgba(156, 159, 159),
        border: 4.5,
        diagonal: 0.06,
        noise: 0.1,
        details: [
            (d) => [36, 408].forEach((x) => {
                drawCircle(d, x, 36, 7, rgba(190, 192, 192, 200), 0.72);
                drawCircle(d, x, 736, 7, rgba(190, 192, 192, 170), 0.6);
            })
        ],
        accentDetails: [
            (d) => {
                for (let y = 92; y < 692; y += 18) {
                    lineDetail(d, 18, y, 34, 2, rgba(255, 255, 255, 90), 0.28);
                    lineDetail(d, 392, y, 34, 2, rgba(255, 255, 255, 80), 0.24);
                }
            }
        ]
    },
    {
        file: 'fob_moto.png',
        seed: 37,
        mask: poly([[92, 0], [352, 0], [422, 126], [400, 638], [334, 772], [110, 772], [44, 638], [22, 126]]),
        top: rgba(38, 47, 51),
        bottom: rgba(5, 7, 8),
        borderColor: rgba(151, 164, 168),
        border: 3.6,
        diagonal: 0.16,
        noise: 0.06,
        details: [
            (d) => drawCircle(d, 222, 62, 20, rgba(230, 244, 248, 52), 0.28)
        ],
        accentDetails: [
            (d) => lineDetail(d, 86, 168, 8, 430, rgba(255, 255, 255, 150), 0.32),
            (d) => lineDetail(d, 350, 168, 8, 430, rgba(255, 255, 255, 120), 0.26)
        ]
    },
    {
        file: 'fob_aero.png',
        seed: 43,
        mask: poly([[78, 0], [366, 0], [434, 94], [414, 612], [352, 772], [92, 772], [30, 612], [10, 94]]),
        top: rgba(46, 61, 70),
        bottom: rgba(4, 8, 10),
        borderColor: rgba(163, 176, 182),
        border: 3.8,
        diagonal: 0.18,
        noise: 0.055,
        details: [
            (d) => {
                for (let y = 90; y < 650; y += 36) {
                    lineDetail(d, 94, y, 256, 1, rgba(255, 255, 255, 42), 0.22);
                }
            }
        ],
        accentDetails: [
            (d) => lineDetail(d, 64, 84, 10, 552, rgba(255, 255, 255, 175), 0.4),
            (d) => lineDetail(d, 370, 84, 10, 552, rgba(255, 255, 255, 140), 0.3),
            (d) => lineDetail(d, 104, 46, 236, 2, rgba(255, 255, 255, 165), 0.3)
        ]
    }
];

frames.forEach(drawFrame);
console.log(`Generated ${frames.length} fob frames and accent masks in ${outDir}`);
