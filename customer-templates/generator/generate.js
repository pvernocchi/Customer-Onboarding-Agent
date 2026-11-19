// Dependency-free generator for the customer onboarding Word templates.
// Usage: node generate.js [outputDir]   (Node.js 22+; uses zlib.crc32)
'use strict';
const fs = require('fs');
const path = require('path');
const zlib = require('zlib');
const forms = require('./forms');

const esc = (s) => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');

function run(text, { b = false, i = false, size } = {}) {
  const rpr = [b ? '<w:b/>' : '', i ? '<w:i/>' : '', size ? `<w:sz w:val="${size}"/><w:szCs w:val="${size}"/>` : ''].join('');
  return `<w:r>${rpr ? `<w:rPr>${rpr}</w:rPr>` : ''}<w:t xml:space="preserve">${esc(text)}</w:t></w:r>`;
}

function para(text = '', { style, b, i, size, keepNext } = {}) {
  const ppr = [style ? `<w:pStyle w:val="${style}"/>` : '', keepNext ? '<w:keepNext/>' : ''].join('');
  const lines = String(text).split('\n');
  const runs = lines.map((l, idx) => (idx ? '<w:r><w:br/></w:r>' : '') + (l ? run(l, { b, i, size }) : '')).join('');
  return `<w:p>${ppr ? `<w:pPr>${ppr}</w:pPr>` : ''}${runs}</w:p>`;
}

function cell(content, width, { shade, span } = {}) {
  const tcpr = `<w:tcW w:w="${width}" w:type="dxa"/>${span ? `<w:gridSpan w:val="${span}"/>` : ''}${shade ? `<w:shd w:val="clear" w:color="auto" w:fill="${shade}"/>` : ''}`;
  return `<w:tc><w:tcPr>${tcpr}</w:tcPr>${content}</w:tc>`;
}

const PAGE_WIDTH = 9906; // A4 text width with 1000 twip margins

function table(widths, rows) {
  const grid = widths.map((w) => `<w:gridCol w:w="${w}"/>`).join('');
  return `<w:tbl><w:tblPr><w:tblStyle w:val="TableGrid"/><w:tblW w:w="${PAGE_WIDTH}" w:type="dxa"/><w:tblLayout w:type="fixed"/></w:tblPr><w:tblGrid>${grid}</w:tblGrid>${rows.join('')}</w:tbl>${para('')}`;
}

function fields(rows) {
  const w = [3600, PAGE_WIDTH - 3600];
  return table(w, rows.map(([label, value = '']) =>
    `<w:tr><w:trPr><w:cantSplit/></w:trPr>${cell(para(label, { b: true }), w[0], { shade: 'EDEFF2' })}${cell(para(value), w[1])}</w:tr>`));
}

function grid(headers, n, rowHeight = 400) {
  const each = Math.floor(PAGE_WIDTH / headers.length);
  const w = headers.map(() => each);
  const head = `<w:tr><w:trPr><w:tblHeader/></w:trPr>${headers.map((h, k) => cell(para(h, { b: true, size: 18 }), w[k], { shade: 'D9DEE7' })).join('')}</w:tr>`;
  const body = Array.from({ length: n }, () =>
    `<w:tr><w:trPr><w:trHeight w:val="${rowHeight}"/></w:trPr>${w.map((x) => cell(para(''), x)).join('')}</w:tr>`);
  return table(w, [head, ...body]);
}

function box(text, fill = 'FFF4E5') {
  return table([PAGE_WIDTH], [`<w:tr>${cell(para(text, { size: 18 }), PAGE_WIDTH, { shade: fill })}</w:tr>`]);
}

function render(block) {
  switch (block.t) {
    case 'h1': return para(block.text, { style: 'Heading1', keepNext: true });
    case 'h2': return para(block.text, { style: 'Heading2', keepNext: true });
    case 'p': return para(block.text, { b: block.b, i: block.i, size: block.size });
    case 'fields': return fields(block.rows);
    case 'grid': return grid(block.headers, block.rows, block.height);
    case 'box': return box(block.text, block.fill);
    case 'break': return '<w:p><w:r><w:br w:type="page"/></w:r></w:p>';
    default: throw new Error(`Unknown block type ${block.t}`);
  }
}

function documentXml(form) {
  const head = [
    para(form.title, { style: 'Title' }),
    para(`${form.code} · Version ${forms.VERSION} · [BANK NAME]`, { i: true, size: 18 }),
    box(forms.DRAFT_NOTICE, 'FDECEC'),
  ];
  const body = [...head, ...form.blocks.map(render)].join('');
  const sect = '<w:sectPr><w:pgSz w:w="11906" w:h="16838"/><w:pgMar w:top="1000" w:right="1000" w:bottom="1000" w:left="1000" w:header="500" w:footer="500" w:gutter="0"/></w:sectPr>';
  return `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><w:body>${body}${sect}</w:body></w:document>`;
}

const STYLES = `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
<w:docDefaults><w:rPrDefault><w:rPr><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri" w:eastAsia="Calibri" w:cs="Calibri"/><w:sz w:val="20"/><w:szCs w:val="20"/><w:lang w:val="en-GB"/></w:rPr></w:rPrDefault><w:pPrDefault><w:pPr><w:spacing w:after="60" w:line="259" w:lineRule="auto"/></w:pPr></w:pPrDefault></w:docDefaults>
<w:style w:type="paragraph" w:default="1" w:styleId="Normal"><w:name w:val="Normal"/><w:qFormat/></w:style>
<w:style w:type="paragraph" w:styleId="Title"><w:name w:val="Title"/><w:basedOn w:val="Normal"/><w:next w:val="Normal"/><w:qFormat/><w:pPr><w:spacing w:after="80"/></w:pPr><w:rPr><w:b/><w:color w:val="1F3864"/><w:sz w:val="36"/><w:szCs w:val="36"/></w:rPr></w:style>
<w:style w:type="paragraph" w:styleId="Heading1"><w:name w:val="heading 1"/><w:basedOn w:val="Normal"/><w:next w:val="Normal"/><w:qFormat/><w:pPr><w:keepNext/><w:spacing w:before="240" w:after="80"/><w:outlineLvl w:val="0"/></w:pPr><w:rPr><w:b/><w:color w:val="1F3864"/><w:sz w:val="26"/><w:szCs w:val="26"/></w:rPr></w:style>
<w:style w:type="paragraph" w:styleId="Heading2"><w:name w:val="heading 2"/><w:basedOn w:val="Normal"/><w:next w:val="Normal"/><w:qFormat/><w:pPr><w:keepNext/><w:spacing w:before="160" w:after="60"/><w:outlineLvl w:val="1"/></w:pPr><w:rPr><w:b/><w:color w:val="2F5496"/><w:sz w:val="22"/><w:szCs w:val="22"/></w:rPr></w:style>
<w:style w:type="table" w:default="1" w:styleId="TableNormal"><w:name w:val="Normal Table"/><w:tblPr><w:tblInd w:w="0" w:type="dxa"/><w:tblCellMar><w:top w:w="0" w:type="dxa"/><w:left w:w="108" w:type="dxa"/><w:bottom w:w="0" w:type="dxa"/><w:right w:w="108" w:type="dxa"/></w:tblCellMar></w:tblPr></w:style>
<w:style w:type="table" w:styleId="TableGrid"><w:name w:val="Table Grid"/><w:basedOn w:val="TableNormal"/><w:pPr><w:spacing w:after="0" w:line="240" w:lineRule="auto"/></w:pPr><w:tblPr><w:tblBorders><w:top w:val="single" w:sz="4" w:space="0" w:color="8C96A8"/><w:left w:val="single" w:sz="4" w:space="0" w:color="8C96A8"/><w:bottom w:val="single" w:sz="4" w:space="0" w:color="8C96A8"/><w:right w:val="single" w:sz="4" w:space="0" w:color="8C96A8"/><w:insideH w:val="single" w:sz="4" w:space="0" w:color="8C96A8"/><w:insideV w:val="single" w:sz="4" w:space="0" w:color="8C96A8"/></w:tblBorders><w:tblCellMar><w:top w:w="40" w:type="dxa"/><w:bottom w:w="40" w:type="dxa"/></w:tblCellMar></w:tblPr></w:style>
</w:styles>`;

const CONTENT_TYPES = `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/><Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/><Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/></Types>`;

const ROOT_RELS = `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/><Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/></Relationships>`;

const DOC_RELS = `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/></Relationships>`;

const coreXml = (form) => `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><dc:title>${esc(`${form.code} ${form.title}`)}</dc:title><dc:subject>Customer onboarding template ${esc(forms.VERSION)}</dc:subject><dc:creator>Customer Onboarding Agent project</dc:creator><cp:keywords>${esc(form.code)}</cp:keywords></cp:coreProperties>`;

// Minimal ZIP writer (deflate) — sufficient for OOXML packages.
function zip(entries) {
  const local = [];
  const central = [];
  let offset = 0;
  const DOS_TIME = 0; // 00:00:00
  const DOS_DATE = ((2026 - 1980) << 9) | (1 << 5) | 1; // fixed date for reproducible output
  for (const [name, content] of entries) {
    const data = Buffer.from(content, 'utf8');
    const comp = zlib.deflateRawSync(data);
    const crc = zlib.crc32(data) >>> 0;
    const nameBuf = Buffer.from(name, 'utf8');
    const lh = Buffer.alloc(30);
    lh.writeUInt32LE(0x04034b50, 0); lh.writeUInt16LE(20, 4); lh.writeUInt16LE(0x0800, 6); lh.writeUInt16LE(8, 8);
    lh.writeUInt16LE(DOS_TIME, 10); lh.writeUInt16LE(DOS_DATE, 12); lh.writeUInt32LE(crc, 14);
    lh.writeUInt32LE(comp.length, 18); lh.writeUInt32LE(data.length, 22); lh.writeUInt16LE(nameBuf.length, 26); lh.writeUInt16LE(0, 28);
    local.push(lh, nameBuf, comp);
    const ch = Buffer.alloc(46);
    ch.writeUInt32LE(0x02014b50, 0); ch.writeUInt16LE(20, 4); ch.writeUInt16LE(20, 6); ch.writeUInt16LE(0x0800, 8); ch.writeUInt16LE(8, 10);
    ch.writeUInt16LE(DOS_TIME, 12); ch.writeUInt16LE(DOS_DATE, 14); ch.writeUInt32LE(crc, 16); ch.writeUInt32LE(comp.length, 20);
    ch.writeUInt32LE(data.length, 24); ch.writeUInt16LE(nameBuf.length, 28); ch.writeUInt16LE(0, 30); ch.writeUInt16LE(0, 32);
    ch.writeUInt16LE(0, 34); ch.writeUInt16LE(0, 36); ch.writeUInt32LE(0, 38); ch.writeUInt32LE(offset, 42);
    central.push(ch, nameBuf);
    offset += 30 + nameBuf.length + comp.length;
  }
  const cd = Buffer.concat(central);
  const end = Buffer.alloc(22);
  end.writeUInt32LE(0x06054b50, 0); end.writeUInt16LE(0, 4); end.writeUInt16LE(0, 6);
  end.writeUInt16LE(entries.length, 8); end.writeUInt16LE(entries.length, 10); end.writeUInt32LE(cd.length, 12); end.writeUInt32LE(offset, 16); end.writeUInt16LE(0, 20);
  return Buffer.concat([...local, cd, end]);
}

const outDir = path.resolve(process.argv[2] || path.join(__dirname, '..'));
fs.mkdirSync(outDir, { recursive: true });
for (const form of forms.FORMS) {
  const buf = zip([
    ['[Content_Types].xml', CONTENT_TYPES],
    ['_rels/.rels', ROOT_RELS],
    ['docProps/core.xml', coreXml(form)],
    ['word/_rels/document.xml.rels', DOC_RELS],
    ['word/styles.xml', STYLES],
    ['word/document.xml', documentXml(form)],
  ]);
  const file = path.join(outDir, `${form.file}.docx`);
  fs.writeFileSync(file, buf);
  console.log(`${form.code}  ${path.basename(file)}  ${buf.length} bytes`);
}
