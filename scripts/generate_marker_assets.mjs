import fs from 'fs'
import zlib from 'zlib'
import path from 'path'

function crc32(buf) {
  const table = new Int32Array(256)
  for (let i = 0; i < 256; i++) {
    let c = i
    for (let k = 0; k < 8; k++) {
      c = (c & 1) ? (0xEDB88320 ^ (c >>> 1)) : (c >>> 1)
    }
    table[i] = c
  }
  let crc = -1
  for (let i = 0; i < buf.length; i++) {
    crc = (crc >>> 8) ^ table[(crc ^ buf[i]) & 0xFF]
  }
  return (crc ^ (-1)) >>> 0
}

function makePng(width, height, getPixel) {
  const rowLen = 1 + width * 4
  const raw = Buffer.alloc(rowLen * height)
  for (let y = 0; y < height; y++) {
    raw[y * rowLen] = 0 // Filter type: None
    for (let x = 0; x < width; x++) {
      const [r, g, b, a = 255] = getPixel(x, y)
      const idx = y * rowLen + 1 + x * 4
      raw[idx] = r
      raw[idx + 1] = g
      raw[idx + 2] = b
      raw[idx + 3] = a
    }
  }
  const compressed = zlib.deflateSync(raw, { level: 9 })

  const signature = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10])

  function chunk(type, data) {
    const len = Buffer.alloc(4)
    len.writeUInt32BE(data.length, 0)
    const typeBuf = Buffer.from(type, 'ascii')
    const crcBuf = Buffer.alloc(4)
    const crcVal = crc32(Buffer.concat([typeBuf, data]))
    crcBuf.writeUInt32BE(crcVal, 0)
    return Buffer.concat([len, typeBuf, data, crcBuf])
  }

  const ihdr = Buffer.alloc(13)
  ihdr.writeUInt32BE(width, 0)
  ihdr.writeUInt32BE(height, 4)
  ihdr[8] = 8 // 8-bit depth
  ihdr[9] = 6 // RGBA
  ihdr[10] = 0 // Deflate
  ihdr[11] = 0 // Standard filter
  ihdr[12] = 0 // No interlace

  return Buffer.concat([
    signature,
    chunk('IHDR', ihdr),
    chunk('IDAT', compressed),
    chunk('IEND', Buffer.alloc(0))
  ])
}

const outDir = path.resolve('textures')

// 1. waysigns_marker.png (16x16) - Professional pixel art stylus marker
const markerGrid = [
  // 16 rows of 16 characters
  // . = transparent
  // o = outline (#1a1a1f)
  // c = coal tip (#2b2d35)
  // C = coal highlight (#484c59)
  // s = steel ferrule (#8fa1b3)
  // S = steel highlight (#dce4ec)
  // d = dark steel (#556371)
  // w = wood shaft (#9e6438)
  // W = wood highlight (#c98c58)
  // b = wood shadow (#6e3e1e)
  // e = end cap (#abb9c7)
  // E = end cap highlight (#e6edf4)
  "................", // 0
  "..............o.", // 1
  "............oEeo", // 2
  "...........oWWeo", // 3
  "..........oWWwbo", // 4
  ".........oWWwbo.", // 5
  "........oWWwbo..", // 6
  ".......oWWwbo...", // 7
  "......oWWwbo....", // 8
  ".....oSSsdo.....", // 9
  "....oSSsdo......", // 10
  "...oCCco........", // 11
  "..occo..........", // 12
  ".oco............", // 13
  ".o..............", // 14
  "................", // 15
]

const markerPalette = {
  '.': [0, 0, 0, 0],
  'o': [24, 24, 28, 245],
  'c': [36, 38, 46, 255],
  'C': [68, 72, 86, 255],
  's': [142, 160, 178, 255],
  'S': [222, 230, 238, 255],
  'd': [86, 98, 112, 255],
  'w': [158, 100, 56, 255],
  'W': [204, 140, 90, 255],
  'b': [110, 62, 30, 255],
  'e': [172, 186, 200, 255],
  'E': [236, 242, 248, 255],
}

const markerPng = makePng(16, 16, (x, y) => {
  const char = markerGrid[y][x] || '.'
  return markerPalette[char] || [0, 0, 0, 0]
})
fs.writeFileSync(path.join(outDir, 'waysigns_marker.png'), markerPng)
console.log('Created waysigns_marker.png')

// 2. waysigns_sign_slate.png (28x20) - Charcoal slate stone plaque
const slatePng = makePng(28, 20, (x, y) => {
  // Bevel borders
  if (y === 0 || x === 0) {
    return [78, 92, 110, 255] // light bevel top/left
  }
  if (y === 19 || x === 27) {
    return [16, 22, 30, 255] // dark shadow bottom/right
  }
  if (y === 1 || x === 1) {
    return [60, 72, 88, 255] // inner highlight
  }
  if (y === 18 || x === 26) {
    return [24, 32, 42, 255] // inner shadow
  }

  // Stone face texture with horizontal cleavage / mineral noise
  const hash = (x * 37 + y * 73 + (x ^ (y * 11))) % 17
  const base = 34 + (hash % 6) * 3
  const isGrain = (y % 4 === 1 && (x % 5 === 0 || x % 7 === 1)) || (y % 5 === 2 && x % 6 === 2)
  const isHighlight = (hash === 2 || hash === 7)

  let r = base
  let g = base + 4
  let b = base + 10

  if (isGrain) {
    r += 12
    g += 14
    b += 18
  } else if (isHighlight) {
    r += 6
    g += 8
    b += 12
  }

  return [Math.min(255, r), Math.min(255, g), Math.min(255, b), 255]
})
fs.writeFileSync(path.join(outDir, 'waysigns_sign_slate.png'), slatePng)
console.log('Created waysigns_sign_slate.png')

// 3. waysigns_sign_gold.png (28x20) - Polished brass/gold plaque
const goldPng = makePng(28, 20, (x, y) => {
  // Bevel borders
  if (y === 0 || x === 0) {
    return [255, 248, 180, 255] // bright gold highlight
  }
  if (y === 19 || x === 27) {
    return [120, 80, 10, 255] // deep bronze shadow
  }
  if (y === 1 || x === 1) {
    return [255, 230, 110, 255] // inner rim
  }
  if (y === 18 || x === 26) {
    return [150, 102, 16, 255] // inner shadow
  }

  // Polished metallic diagonal specular sheen
  const diag = (x + y * 1.3)
  const sheen = Math.sin(diag * 0.3) * 14
  const hash = (x * 19 + y * 41) % 11

  const r = 236 + Math.floor(sheen) + (hash % 4) * 3
  const g = 176 + Math.floor(sheen * 0.85) + (hash % 4) * 2
  const b = 32 + Math.floor(sheen * 0.4)

  return [Math.min(255, Math.max(0, r)), Math.min(255, Math.max(0, g)), Math.min(255, Math.max(0, b)), 255]
})
fs.writeFileSync(path.join(outDir, 'waysigns_sign_gold.png'), goldPng)
console.log('Created waysigns_sign_gold.png')

// 4. waysigns_sign_glass.png (28x20) - Translucent frosted glass plaque
const glassPng = makePng(28, 20, (x, y) => {
  // Bevel borders
  if (y === 0 || x === 0) {
    return [224, 247, 250, 240] // icy edge highlight
  }
  if (y === 19 || x === 27) {
    return [0, 96, 108, 210] // teal/cyan refraction rim
  }
  if (y === 1 || x === 1) {
    return [200, 236, 242, 220]
  }
  if (y === 18 || x === 26) {
    return [30, 120, 134, 200]
  }

  // Frosted translucent matrix with micro-refractions
  const hash = (x * 47 + y * 61 + (x ^ (y * 7))) % 13
  const noise = (hash % 5) * 4
  const r = 190 + noise
  const g = 224 + noise
  const b = 232 + noise
  const alpha = 165 + (hash % 4) * 10

  return [Math.min(255, r), Math.min(255, g), Math.min(255, b), Math.min(255, alpha)]
})
fs.writeFileSync(path.join(outDir, 'waysigns_sign_glass.png'), glassPng)
console.log('Created waysigns_sign_glass.png')
