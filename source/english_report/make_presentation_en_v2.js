// English project — mini-presentation, design 2: "open" layout without boxes or borders.
// Structure comes from hairline rules, large numerals and white space instead of filled cards
// (the outline DAG on slide 2 keeps its boxes).
// Usage (from this folder):  node make_presentation_en_v2.js Presentation.pptx
// No click animations or transitions: every slide appears at once; the looping GIFs
// (experiments/make_gifs_en.py) provide the movement.
const fs = require("fs");
const path = require("path");
const pptxgen = require("pptxgenjs");

const OUT = process.argv[2] || "Presentation_EN_design2.pptx";
const FS = "../aide500_report/figures_slides/";
const FE = "figures/";
const LOGO1 = "figures/logo1.png"; // ../image.png cropped to its visible square
const LOGO2 = "figures/logo2.png";
const D = JSON.parse(fs.readFileSync("experiments/nas_comparison.json", "utf8"));
const fx = (x, d = 1) => Number(x).toFixed(d);

const THEME = {
  name: "EuroSAT English",
  headFontFace: "Cambria",
  bodyFontFace: "Calibri",
  colors: {
    dk1: "1F2A24", lt1: "FFFFFF", dk2: "13613F", lt2: "EEF4F0",
    accent1: "13613F", accent2: "2F6DB5", accent3: "5E8C6A", accent4: "8C9A92", accent5: "C77C02", accent6: "C9A227",
    hlink: "2F6DB5", folHlink: "5E8C6A",
  },
};
const pres = new pptxgen();
pres.layout = "LAYOUT_WIDE"; // 13.333 x 7.5 in
pres.author = "Emilio Yared";
pres.title = "Designing CNNs for Satellite Image Classification";
pres.theme = { headFontFace: THEME.headFontFace, bodyFontFace: THEME.bodyFontFace };
const C = pres.SchemeColor;

pres.defineSlideMaster({
  title: "TITLE",
  background: { color: C.background1 },
  objects: [
    { placeholder: { options: { name: "title", type: "title", x: 0.8, y: 1.9, w: 10.4, h: 2.0, fontFace: "Cambria", fontSize: 40, bold: true, color: C.accent1, valign: "bottom", align: "left", margin: 0 }, text: "" } },
    { placeholder: { options: { name: "body", type: "body", x: 0.8, y: 4.05, w: 10.4, h: 0.9, fontSize: 20, color: C.text1, valign: "top", align: "left", margin: 0 }, text: "" } },
  ],
});
pres.defineSlideMaster({
  title: "CONTENT",
  background: { color: C.background1 },
  margin: [0.4, 0.6, 0.6, 0.6],
  objects: [
    { placeholder: { options: { name: "title", type: "title", x: 0.6, y: 0.3, w: 10.7, h: 0.8, fontFace: "Cambria", fontSize: 28, bold: true, color: C.accent1, valign: "middle", align: "left", margin: 0 }, text: "" } },
    { image: { x: 11.47, y: 0.4, w: 0.6, h: 0.6, path: LOGO1 } },
    { image: { x: 12.13, y: 0.4, w: 0.6, h: 0.605, path: LOGO2 } },
    { text: { text: "Designing CNNs for satellite image classification — Emilio Yared", options: { x: 0.6, y: 7.0, w: 9, h: 0.3, fontSize: 10, color: C.accent4, margin: 0 } } },
  ],
  slideNumber: { x: 12.13, y: 7.0, w: 0.6, h: 0.3, fontSize: 10, color: C.accent4, align: "right", margin: 0 },
});

// ---------------------------------------------------------------- helpers
function runs(str, base = {}) {
  return str.split(/(\*\*[^*]+\*\*)/).filter((s) => s).map((s) => s.startsWith("**")
    ? { text: s.slice(2, -2), options: { ...base, bold: true, color: C.accent1 } }
    : { text: s, options: { ...base } });
}
function bullets(slide, items, box, size, name) {
  const all = [];
  items.forEach((s, k) => {
    const r = runs(s, { fontSize: size });
    r[0].options = { ...r[0].options, bullet: { indent: 20 }, paraSpaceAfter: 10 };
    r[r.length - 1].options = { ...r[r.length - 1].options, breakLine: k < items.length - 1 };
    all.push(...r);
  });
  slide.addText(all, { ...box, isTextBox: true, align: "justify", valign: "top", color: C.text1, margin: 0.05, objectName: name });
}
function fig(slide, file, box, name) {
  slide.addImage({ path: file, ...box, sizing: { type: "contain", w: box.w, h: box.h }, objectName: name });
}
function gif(slide, file, x, y, w, ratio, name) {
  slide.addImage({ path: FE + file, x, y, w, h: w / ratio, objectName: name });
  return y + w / ratio;
}
const HAIR = "C9D6CE"; // hairline colour (light grey-green)
function hline(slide, x, y, w, name, color = HAIR, width = 0.75) {
  slide.addShape(pres.ShapeType.line, { x, y, w, h: 0, line: { color, width }, objectName: name });
}
function vline(slide, x, y, h, name) {
  slide.addShape(pres.ShapeType.line, { x, y, w: 0, h, line: { color: HAIR, width: 0.75 }, objectName: name });
}
// big number + label under a short green rule (2 objects: name, name + " text")
function stat(slide, value, label, x, y, w, h, name) {
  hline(slide, x, y, 0.9, name, C.accent1, 3);
  slide.addText([
    { text: value, options: { fontFace: "Cambria", fontSize: 36, bold: true, color: C.accent1, breakLine: true } },
    { text: label, options: { fontSize: 16, color: C.text1 } },
  ], { x, y: y + 0.12, w, h: h - 0.12, isTextBox: true, align: "left", valign: "middle", margin: 0, objectName: name + " text" });
}
// numbered column: large light numeral, short rule, title, justified body
function column(slide, num, title, body, x, y, w, h, sizes, name) {
  slide.addText(String(num).padStart(2, "0"), { x, y, w, h: 0.8, isTextBox: true, fontFace: "Cambria", fontSize: 44, bold: true, color: C.accent3, align: "left", valign: "bottom", margin: 0, objectName: name + " num" });
  hline(slide, x, y + 0.92, 0.9, name + " rule", C.accent1, 3);
  slide.addText([
    { text: title, options: { fontFace: "Cambria", fontSize: sizes[0], bold: true, color: C.accent1, breakLine: true, paraSpaceAfter: 8 } },
    { text: body, options: { fontSize: sizes[1], color: C.text1 } },
  ], { x, y: y + 1.1, w, h: h - 1.1, isTextBox: true, align: "justify", valign: "top", margin: 0, objectName: name + " text" });
}
// three numbered columns separated by vertical hairlines
function columns(slide, items, y, h, sizes, name) {
  const W = 3.75, G = (12.13 - 3 * W) / 2;
  items.forEach(([t, b], k) => {
    const x = 0.6 + k * (W + G);
    if (k) vline(slide, x - G / 2, y + 0.1, h - 0.2, name + " divider" + k);
    column(slide, k + 1, t, b, x, y, W, h, sizes, name + (k + 1));
  });
}
// booktabs-style table: no fills, green rules at the top and bottom, hairlines between rows
function table(slide, rows, box, opts, name) {
  const none = { type: "none" };
  const green = { type: "solid", pt: 2, color: THEME.colors.accent1 };
  const body = rows.map((row, i) => row.map((cell, j) => ({
    text: String(cell),
    options: {
      bold: i === 0 || (opts.highlight || []).includes(i),
      color: i === 0 || (opts.highlight || []).includes(i) ? C.accent1 : C.text1,
      align: j === 0 ? "left" : "center", fontSize: opts.fontSize || 16,
      border: [i === 0 ? green : none, none, i === 0 || i === rows.length - 1 ? green : { type: "solid", pt: 0.5, color: HAIR }, none],
    },
  })));
  slide.addTable(body, { ...box, margin: [4, 8, 4, 0], valign: "middle", rowH: opts.rowH || 0.42, objectName: name });
}
const content = (title, section) => {
  const s = pres.addSlide({ masterName: "CONTENT", sectionTitle: section });
  s.addText(title, { placeholder: "title" });
  return s;
};
const step = (slide, num, title, body, x, y, w, name) => {
  slide.addText("0" + num, { x, y: y - 0.12, w: 0.8, h: 0.75, isTextBox: true, align: "left", valign: "top", fontFace: "Cambria", fontSize: 36, bold: true, color: C.accent3, margin: 0, objectName: name + " num" });
  slide.addText([
    { text: title, options: { bold: true, fontSize: 18, color: C.accent1, breakLine: true } },
    { text: body, options: { fontSize: 15, color: C.text1 } },
  ], { x: x + 0.8, y: y - 0.08, w, h: 1.0, isTextBox: true, align: "justify", valign: "top", margin: 0, objectName: name + " text" });
};

// ================================================================ slides
// 1. title
pres.addSection({ title: "Introduction" });
let s = pres.addSlide({ masterName: "TITLE", sectionTitle: "Introduction" });
s.addText("MINI-PRESENTATION  ·  SCIENTIFIC ENGLISH FOR AI", { x: 0.8, y: 0.75, w: 9, h: 0.4, isTextBox: true, fontSize: 14, bold: true, charSpacing: 2, color: C.accent3, margin: 0 });
s.addImage({ path: LOGO1, x: 9.73, y: 0.75, w: 1.3, h: 1.3, objectName: "logo 1" });
s.addImage({ path: LOGO2, x: 11.23, y: 0.75, w: 1.3, h: 1.31, objectName: "logo 2" });
s.addText("Designing CNNs for Satellite Image Classification", { placeholder: "title" });
s.addText("Hand-design, transfer learning and training-free architecture search on EuroSAT", { placeholder: "body" });
s.addText([
  { text: "Emilio Yared", options: { bold: true, breakLine: true } },
  { text: "Master 2 Artificial Intelligence and Data Engineering  ·  Presented to Dr. Zeinab Abbas" },
], { x: 0.8, y: 5.5, w: 11, h: 0.9, isTextBox: true, fontSize: 16, color: C.text1, margin: 0, valign: "top", objectName: "author" });

// outline: the talk as a DAG (an arrow means "builds on"); 6 columns between x = 0.6 and 12.73
s = content("Outline of the presentation", "Introduction");
const NW = 1.62, NH = 0.95, GAP = (12.13 - 6 * NW) / 5;
const colX = (c) => 0.6 + c * (NW + GAP);
const N = {
  obj: [0, 3.45, "Objective", 3, true], data: [1, 3.45, "EuroSAT data, three approaches", 4],
  hand: [2, 2.25, "Hand-design", 4], trans: [2, 3.45, "Transfer learning", 4], nas: [2, 4.65, "Training-free search (NASWOT)", 5],
  r1: [3, 2.85, "Hand-design vs transfer", 6], r2: [3, 4.65, "NASWOT vs 5 strategies", 7], r3: [3, 5.85, "Search on EuroSAT", 8],
  fin: [4, 3.45, "Final comparison", 9], concl: [5, 3.45, "Conclusion", 10, true], q: [5, 4.65, "Questions", 11, true],
};
[["Introduction", 0, 0], ["Methods", 1, 2], ["Results", 3, 4], ["Conclusion", 5, 5]].forEach(([t, a, b]) => {
  const x = colX(a), w = colX(b) + NW - x;
  s.addText(t, { x, y: 1.3, w, h: 0.4, isTextBox: true, fontFace: "Cambria", fontSize: 18, bold: true, color: C.accent1, align: "center", valign: "middle", margin: 0, objectName: "section " + t });
  s.addShape(pres.ShapeType.line, { x, y: 1.72, w, h: 0, line: { color: C.accent3, width: 1.5 }, objectName: "rule " + t });
});
Object.entries(N).forEach(([k, [c, cy, label, slideNo, strong]]) => {
  s.addShape(pres.ShapeType.roundRect, { x: colX(c), y: cy - NH / 2, w: NW, h: NH, rectRadius: 0.1, fill: { color: strong ? C.accent1 : C.background2 }, line: { color: C.accent1, width: 1.25 }, objectName: "node " + k });
  s.addText([
    { text: label, options: { bold: true, fontSize: 14, color: strong ? C.background1 : C.accent1, breakLine: true } },
    { text: "slide " + slideNo, options: { fontSize: 11, color: strong ? C.background2 : C.accent4 } },
  ], { x: colX(c) + 0.06, y: cy - NH / 2, w: NW - 0.12, h: NH, isTextBox: true, align: "center", valign: "middle", margin: 0, objectName: "node " + k + " text" });
});
const arrow = (a, b) => {
  const [ca, ya] = N[a], [cb, yb] = N[b];
  const [x1, y1, x2, y2] = ca === cb ? [colX(ca) + NW / 2, ya + NH / 2, colX(cb) + NW / 2, yb - NH / 2]
    : [colX(ca) + NW, ya, colX(cb), yb];
  s.addShape(pres.ShapeType.line, { x: Math.min(x1, x2), y: Math.min(y1, y2), w: Math.abs(x2 - x1), h: Math.abs(y2 - y1), flipV: y2 < y1,
    line: { color: C.accent3, width: 1.75, endArrowType: "triangle" }, objectName: "edge " + a + "-" + b });
};
[["obj", "data"], ["data", "hand"], ["data", "trans"], ["data", "nas"], ["hand", "r1"], ["trans", "r1"], ["nas", "r2"], ["r2", "r3"],
 ["r1", "fin"], ["r3", "fin"], ["fin", "concl"], ["concl", "q"]].forEach(([a, b]) => arrow(a, b));
s.addText("Each box is one part of the talk; an arrow shows which earlier part it builds on.", { x: 0.6, y: 6.5, w: 12.13, h: 0.4, isTextBox: true, fontSize: 15, italic: true, color: C.accent4, align: "center", margin: 0, objectName: "outline caption" });

// 2. objective
s = content("Objective", "Introduction");
stat(s, "27,000", "satellite images, 10 land-use classes (EuroSAT)", 0.6, 1.45, 3.9, 1.95, "stat1");
stat(s, "800 GPUs", "for 28 days: cost of the first automatic search (Zoph & Le, 2017)", 0.6, 3.75, 3.9, 1.95, "stat2");
s.addText("Problem", { x: 5.0, y: 1.45, w: 7.7, h: 0.5, isTextBox: true, fontFace: "Cambria", fontSize: 22, bold: true, color: C.accent1, margin: 0, objectName: "problem head" });
s.addText("Designing a neural network by hand is slow: every new idea requires a complete training run.", { x: 5.0, y: 1.95, w: 7.7, h: 0.9, isTextBox: true, fontSize: 18, color: C.text1, margin: 0, align: "justify", valign: "top", objectName: "problem text" });
s.addText("Objective: compare three ways of building a classifier", { x: 5.0, y: 3.05, w: 7.7, h: 0.5, isTextBox: true, fontFace: "Cambria", fontSize: 22, bold: true, color: C.accent1, margin: 0, objectName: "objective head" });
s.addText([
  { text: "Design a CNN by hand, step by step", options: { bullet: { type: "number" }, breakLine: true, paraSpaceAfter: 10 } },
  { text: "Reuse a network pretrained on ImageNet", options: { bullet: { type: "number" }, breakLine: true, paraSpaceAfter: 10 } },
  { text: "Search the architecture automatically, without training", options: { bullet: { type: "number" } } },
], { x: 5.0, y: 3.65, w: 7.7, h: 2.0, isTextBox: true, align: "justify",  fontSize: 19, color: C.text1, margin: 0.05, valign: "top", objectName: "objectives" });

// 3. method: data + approaches
pres.addSection({ title: "Methods" });
s = content("Method: data and three approaches", "Methods");
gif(s, "gif_classes.gif", 0.6, 1.4, 12.13, 1626 / 184, "classes");
s.addText("Same split for all models: 18,900 training · 4,050 validation · 4,050 test images", { x: 0.6, y: 3.0, w: 12.1, h: 0.45, isTextBox: true, fontSize: 16, italic: true, color: C.accent4, align: "center", margin: 0, objectName: "split" });
columns(s, [["Hand-design", "Baseline CNN improved one factor at a time: depth, kernels, optimiser, augmentation"],
  ["Transfer learning", "ResNet-18 pretrained on ImageNet, fine-tuned with 5% to 100% of the data"],
  ["Training-free search", "NASWOT scores 1,000 untrained networks in seconds; only the best one is trained"]], 3.6, 3.1, [22, 18], "approach");

// 4. method: NASWOT
s = content("Method: how can a network be judged without training?", "Methods");
step(s, 1, "Take an untrained network", "and pass one batch of 128 images through it", 0.6, 1.5, 5.6, "step1");
step(s, 2, "Record which ReLU units are active", "this gives a binary code for every image", 0.6, 2.85, 5.6, "step2");
step(s, 3, "Compare the codes of all images", "different codes = the network can separate the images", 0.6, 4.2, 5.6, "step3");
hline(s, 0.6, 5.55, 6.4, "formula top");
hline(s, 0.6, 6.75, 6.4, "formula bottom");
s.addText("score  s = log |K_H|", { x: 0.6, y: 5.55, w: 6.4, h: 1.2, isTextBox: true, fontFace: "Cambria", fontSize: 26, italic: true, bold: true, color: C.accent1, align: "center", valign: "middle", margin: 0, objectName: "formula text" });
gif(s, "gif_naswot.gif", 7.4, 1.4, 5.33, 800 / 440, "naswot gif");
s.addText([
  { text: "Validated first on NAS-Bench-201", options: { bold: true, color: C.accent1, fontSize: 18, breakLine: true } },
  { text: "15,625 networks whose trained accuracy is already known, which allows a fair comparison with 5 other search strategies.", options: { fontSize: 16 } },
], { x: 7.4, y: 4.55, w: 5.33, h: 2.2, isTextBox: true, align: "justify", valign: "top", color: C.text1, margin: 0, objectName: "benchmark" });

// 5. results: hand-design + transfer
pres.addSection({ title: "Results" });
s = content("Results: hand-design and transfer learning", "Results");
fig(s, FS + "nb5_transfer.png", { x: 0.6, y: 1.3, w: 7.2, h: 4.35 }, "transfer fig");
s.addText("Test accuracy versus amount of training data", { x: 0.6, y: 5.7, w: 7.1, h: 0.4, isTextBox: true, fontSize: 13, italic: true, color: C.accent4, align: "center", margin: 0, objectName: "transfer caption" });
stat(s, "90.2% → 97.0%", "hand-designed CNN after the step-by-step study", 8.15, 1.3, 4.58, 1.65, "statA");
stat(s, "99.0%", "ResNet-18 fully fine-tuned: the most accurate model", 8.15, 3.15, 4.58, 1.65, "statB");
stat(s, "96.0%", "ResNet-18 with only 5% of the data (947 images)", 8.15, 5.0, 4.58, 1.65, "statC");

// 6. results: NAS-Bench-201 comparison
const nw = D.naswot["1000"].mean[1], rea = D.search["Regularised Evolution (REA)"]["100"].mean[1];
const area10 = D.search["Assisted REA (AREA)"]["10"].mean[1], rea10 = D.search["Regularised Evolution (REA)"]["10"].mean[1];
s = content("Results: NASWOT compared with five search strategies", "Results");
gif(s, "gif_anytime.gif", 0.6, 1.4, 7.6, 900 / 520, "anytime");
s.addText("200 runs per strategy on NAS-Bench-201 (CIFAR-10)", { x: 0.6, y: 5.9, w: 7.6, h: 0.4, isTextBox: true, fontSize: 13, italic: true, color: C.accent4, align: "center", margin: 0, objectName: "anytime caption" });
bullets(s, [
  "Published NASWOT results **reproduced within 0.1 point**",
  "NASWOT without training: **" + fx(nw) + "%**, as good as training 10 random networks",
  "Evolution with 100 trained networks: **" + fx(rea) + "%**, better but far more expensive",
  "NASWOT + evolution is **best with small budgets**: " + fx(area10) + "% vs " + fx(rea10) + "% after 10 networks",
], { x: 8.5, y: 1.4, w: 4.23, h: 5.3 }, 17, "nas points");

// 7. results: EuroSAT search
s = content("Results: automatic search on EuroSAT", "Results");
table(s, [["Criterion", "Hand-designed", "NASWOT winner"],
  ["Test accuracy", "96.72%", "97.43%"],
  ["Parameters", "1.24 M", "1.99 M"],
  ["Latency per image", "0.76 ms", "1.31 ms"],
  ["GPU time for the design", "203 min", "17 min"]],
  { x: 0.6, y: 1.5, w: 7.0, colW: [2.9, 2.05, 2.05] }, { fontSize: 17, rowH: 0.55, highlight: [1, 4] }, "eurosat table");
s.addText("Search space: 8,640 CNNs · 1,000 networks scored in 153 s · only the top 3 trained", { x: 0.6, y: 4.5, w: 7.0, h: 0.8, isTextBox: true, fontSize: 16, italic: true, color: C.accent4, margin: 0, align: "justify",  valign: "top", objectName: "space" });
s.addText("The search rediscovered our manual conclusions (deep network, small kernels, batch normalisation) and added residual connections.", { x: 0.6, y: 5.3, w: 7.0, h: 1.3, isTextBox: true, fontSize: 17, color: C.text1, margin: 0, align: "justify",  valign: "top", objectName: "rediscover" });
stat(s, "+0.7 pt", "more accurate than our own design", 8.2, 1.5, 4.53, 2.3, "statD");
stat(s, "12× less", "GPU time than manual design", 8.2, 4.1, 4.53, 2.3, "statE");

// 8. results: final comparison
s = content("Results: no single model is best on every criterion", "Results");
fig(s, FS + "nb7_pareto.png", { x: 0.6, y: 1.45, w: 6.9, h: 5.25 }, "pareto");
table(s, [["Model", "Accuracy", "Size"],
  ["Baseline CNN", "90.15%", "2.19 M"],
  ["Hand-designed", "97.04%", "1.24 M"],
  ["NASWOT winner", "97.43%", "1.99 M"],
  ["ResNet-18", "99.04%", "11.18 M"]],
  { x: 7.85, y: 1.45, w: 4.88, colW: [2.0, 1.44, 1.44] }, { fontSize: 16, rowH: 0.5, highlight: [4] }, "final table");
bullets(s, ["ResNet-18 is the most accurate, but **9× larger**", "The CNNs from scratch are the **fastest**", "All 50 models tested on the **same 4,050 images**"],
  { x: 7.85, y: 4.35, w: 4.88, h: 2.3 }, 17, "final points");

// 9. conclusion
pres.addSection({ title: "Conclusion" });
s = content("Conclusion", "Conclusion");
columns(s, [["Transfer learning", "Gives the highest accuracy (99.0%) and works even with very little data."],
  ["Training-free search", "Found a better CNN than our manual design, with 12 times less GPU time."],
  ["A fast filter", "NASWOT does not replace training: combined with evolution, it gives the best results."]], 1.4, 3.7, [24, 20], "concl");
hline(s, 0.6, 5.3, 12.13, "future rule");
s.addText("Future work: several random seeds, the 13 spectral bands of EuroSAT, and a latency constraint in the search.", { x: 0.6, y: 5.45, w: 12.13, h: 0.9, isTextBox: true, fontSize: 19, italic: true, color: C.accent4, align: "center", valign: "middle", margin: 0, objectName: "future" });

// 10. thank you
s = pres.addSlide({ masterName: "TITLE", sectionTitle: "Conclusion" });
s.addImage({ path: LOGO1, x: 9.73, y: 0.75, w: 1.3, h: 1.3, objectName: "logo 1" });
s.addImage({ path: LOGO2, x: 11.23, y: 0.75, w: 1.3, h: 1.31, objectName: "logo 2" });
s.addText("Thank you for your attention", { placeholder: "title" });
s.addText("Questions are welcome", { placeholder: "body" });
s.addText("Emilio Yared  ·  Master 2 Artificial Intelligence and Data Engineering", { x: 0.8, y: 5.5, w: 11, h: 0.5, isTextBox: true, fontSize: 16, bold: true, color: C.text1, margin: 0, objectName: "author" });

(async () => {
  await pres.writeFile({ fileName: OUT });
  const { applyTheme } = require(process.env.APPLY_THEME);
  await applyTheme(OUT, THEME);
  console.log("written", OUT);
})();
