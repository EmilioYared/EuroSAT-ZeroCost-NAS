// AIDE500 — Presentation deck (PowerPoint), built from the result files of the notebooks.
// Usage (from the Report folder):  python make_figures.py slides  &&  node make_presentation.js
// Needs pptxgenjs (NODE_PATH pointing to a node_modules folder that contains it).
const fs = require("fs");
const path = require("path");
const pptxgen = require("pptxgenjs");

const OUT = process.argv[2] || "Presentation.pptx";
const FIG = "figures_slides/";
const R = (nb, file) => JSON.parse(fs.readFileSync(path.join("..", "..", "results", nb, file), "utf8"));
const fx = (x, d = 2) => Number(x).toFixed(d);
const M = (p) => fx(p / 1e6, 2) + "M";

// ---------------------------------------------------------------- data
const nb1 = R("NB1_Baseline_CNN", "NB1_baseline_sgd_lr0.01_bs64_30ep_summary.json");
const nb2 = R("NB2_Architecture_Variations", "NB2_summaries.json").summaries;
const nb3 = R("NB3_Optimizers_LR_Schedulers", "NB3_summaries.json").summaries;
const nb4 = R("NB4_Data_Augmentation", "NB4_summaries.json").summaries;
const b4 = R("NB4_Data_Augmentation", "NB4_best_recipe.json");
const nb5 = R("NB5_Transfer_Learning", "NB5_summaries.json").summaries;
const rep = R("NB6_1_NASBench201_Reproduction", "NB6_1_reproduction.json");
const nas = R("NB6_2_EuroSAT_ZeroCost_NAS", "NB6_2_nas_results.json");
const corr = R("NB6_2_EuroSAT_ZeroCost_NAS", "NB6_2_correlation_study.json").correlations;
const m7 = R("NB7_Final_Evaluation", "NB7_master_results.json").models;

// ---------------------------------------------------------------- theme
// colors of the university logo: green dominant, red as the sharp accent
const THEME = {
  name: "AIDE500 EuroSAT",
  headFontFace: "Cambria",
  bodyFontFace: "Calibri",
  colors: {
    dk1: "1F2A24", lt1: "FFFFFF", dk2: "13613F", lt2: "EEF4F0",
    accent1: "13613F", accent2: "E0352B", accent3: "5E8C6A", accent4: "8C9A92", accent5: "2F6F8F", accent6: "C9A227",
    hlink: "2F6F8F", folHlink: "5E8C6A",
  },
};
const HEX = THEME.colors;

const pres = new pptxgen();
pres.layout = "LAYOUT_WIDE"; // 13.333 x 7.5 in
pres.author = "Emilio Yared, Joe Missisian";
pres.title = "From Hand-Tuning to Architecture Search";
pres.theme = { headFontFace: THEME.headFontFace, bodyFontFace: THEME.bodyFontFace };
const C = pres.SchemeColor;
const W = 13.333, H = 7.5;
const LOGO = "figures/logo.png";

// ---------------------------------------------------------------- layouts
pres.defineSlideMaster({
  title: "TITLE",
  background: { color: C.accent1 },
  objects: [
    { placeholder: { options: { name: "title", type: "title", x: 0.8, y: 2.0, w: 10.6, h: 1.9, fontFace: "Cambria", fontSize: 40, bold: true, color: C.background1, valign: "bottom", align: "left" }, text: "" } },
    { placeholder: { options: { name: "body", type: "body", x: 0.8, y: 4.05, w: 10.6, h: 1.0, fontSize: 20, color: C.background2, valign: "top", align: "left" }, text: "" } },
  ],
});
pres.defineSlideMaster({
  title: "CONTENT",
  background: { color: C.background1 },
  margin: [0.4, 0.6, 0.6, 0.6],
  objects: [
    { placeholder: { options: { name: "title", type: "title", x: 0.6, y: 0.3, w: 11.2, h: 0.8, fontFace: "Cambria", fontSize: 30, bold: true, color: C.accent1, valign: "middle", align: "left" }, text: "" } },
    { image: { x: 12.15, y: 0.32, w: 0.68, h: 0.686, path: LOGO } },
    { text: { text: "AIDE500 — EuroSAT: hand-tuning, transfer learning and zero-cost NAS", options: { x: 0.6, y: 7.0, w: 9, h: 0.3, fontSize: 10, color: C.accent4, margin: 0 } } },
  ],
  slideNumber: { x: 12.2, y: 7.0, w: 0.6, h: 0.3, fontSize: 10, color: C.accent4, align: "right" },
});

// ---------------------------------------------------------------- helpers
// "**bold**" and "[[highlight]]" inside a string -> text runs
function runs(str, base = {}) {
  const out = [];
  str.split(/(\*\*[^*]+\*\*|\[\[[^\]]+\]\])/).filter((s) => s).forEach((s) => {
    if (s.startsWith("**")) out.push({ text: s.slice(2, -2), options: { ...base, bold: true } });
    else if (s.startsWith("[[")) out.push({ text: s.slice(2, -2), options: { ...base, bold: true, color: C.accent2 } });
    else out.push({ text: s, options: { ...base } });
  });
  return out;
}
// bullet list: each item is a string, or [string, level]
function bullets(slide, items, box, size = 17) {
  const all = [];
  items.forEach((it, k) => {
    const [s, lvl] = Array.isArray(it) ? it : [it, 0];
    const r = runs(s, { fontSize: lvl ? size - 2 : size });
    r[0].options = { ...r[0].options, bullet: lvl ? { indent: 18 } : { indent: 18 }, indentLevel: lvl, paraSpaceAfter: 7 };
    r[r.length - 1].options = { ...r[r.length - 1].options, breakLine: k < items.length - 1 };
    all.push(...r);
  });
  slide.addText(all, { ...box, isTextBox: true, valign: "top", color: C.text1, margin: 0.05, objectName: box.name || "bullets" });
}
function text(slide, s, box, size = 14, extra = {}) {
  slide.addText(runs(s, { fontSize: size }), { ...box, isTextBox: true, color: C.text1, margin: 0.05, valign: "top", ...extra });
}
function fig(slide, file, box) {
  slide.addImage({ path: FIG + file, ...box, sizing: { type: "contain", w: box.w, h: box.h }, objectName: file });
}
// native table: first row = header
function table(slide, rows, box, opts = {}) {
  const size = opts.fontSize || 13;
  const body = rows.map((row, i) => row.map((cell, j) => {
    const hlRow = opts.highlight && opts.highlight.includes(i);
    return {
      text: String(cell),
      options: {
        bold: i === 0 || hlRow,
        color: i === 0 ? C.background1 : (hlRow ? C.accent2 : C.text1),
        fill: { color: i === 0 ? C.accent1 : (i % 2 ? C.background1 : C.background2) },
        align: j <= (opts.leftCols || 0) ? "left" : "center",
        fontSize: size,
      },
    };
  }));
  slide.addTable(body, { ...box, border: { type: "solid", pt: 0.5, color: "C9D6CE" }, margin: [3, 6, 3, 6], valign: "middle", rowH: opts.rowH || 0.3 });
}
// rounded card with a big number and a label (stat callout)
function stat(slide, value, label, x, y, w = 2.5) {
  slide.addShape(pres.ShapeType.roundRect, { x, y, w, h: 1.25, rectRadius: 0.12, fill: { color: C.background2 }, line: { color: C.background2 }, objectName: "stat " + label });
  slide.addText(value, { x, y: y + 0.08, w, h: 0.65, isTextBox: true, align: "center", fontFace: "Cambria", fontSize: 28, bold: true, color: C.accent1, margin: 0 });
  slide.addText(label, { x: x + 0.1, y: y + 0.72, w: w - 0.2, h: 0.48, isTextBox: true, align: "center", fontSize: 12, color: C.text1, margin: 0, valign: "top" });
}
const content = (title, section) => {
  const s = pres.addSlide({ masterName: "CONTENT", sectionTitle: section });
  s.addText(title, { placeholder: "title" });
  return s;
};

// ================================================================ slides
// 1. title
pres.addSection({ title: "Introduction" });
let s = pres.addSlide({ masterName: "TITLE", sectionTitle: "Introduction" });
s.addImage({ path: LOGO, x: 11.3, y: 0.6, w: 1.4, h: 1.41, objectName: "logo" });
s.addText("From Hand-Tuning to Architecture Search", { placeholder: "title" });
s.addText("CNN design, transfer learning and zero-cost NAS for satellite land-use classification (EuroSAT)", { placeholder: "body" });
s.addText([
  { text: "Emilio Yared  ·  Joe Missisian  —  Group 7", options: { bold: true, breakLine: true } },
  { text: "Master 2 Artificial Intelligence and Data Engineering", options: { breakLine: true } },
  { text: "AIDE500 — Programming for AI" },
], { x: 0.8, y: 5.4, w: 10, h: 1.2, isTextBox: true, fontSize: 16, color: C.background1, margin: 0, valign: "top" });

// 2. problem and dataset
s = content("Problem and dataset", "Introduction");
fig(s, "classes.png", { x: 0.6, y: 1.25, w: 12.1, h: 3.1 });
bullets(s, [
  "**EuroSAT RGB**: 27,000 Sentinel-2 tiles, 64×64 px, 10 land-use classes",
  "Fixed **stratified split** 70/15/15 (18,900 / 4,050 / 4,050), normalization from the train split only",
  "Classes defined by **texture and color**; several are visually close (crops, vegetation, pasture)",
], { x: 0.6, y: 4.55, w: 6.6, h: 2.3 }, 16);
s.addShape(pres.ShapeType.roundRect, { x: 7.55, y: 4.5, w: 5.15, h: 2.3, rectRadius: 0.1, fill: { color: C.background2 }, line: { color: C.background2 }, objectName: "questions card" });
s.addText([
  { text: "Three questions", options: { bold: true, fontSize: 17, color: C.accent1, breakLine: true, paraSpaceAfter: 6 } },
  { text: "How far can a CNN trained from scratch go? (Tasks 1–2)", options: { bullet: { type: "number" }, fontSize: 15, breakLine: true, paraSpaceAfter: 4 } },
  { text: "What does ImageNet pretraining bring? (Task 3)", options: { bullet: { type: "number" }, fontSize: 15, breakLine: true, paraSpaceAfter: 4 } },
  { text: "Can the manual design be automated cheaply? (zero-cost NAS)", options: { bullet: { type: "number" }, fontSize: 15 } },
], { x: 7.75, y: 4.6, w: 4.8, h: 2.1, isTextBox: true, color: C.text1, margin: 0.05, valign: "top" });

// 3. Task 1
pres.addSection({ title: "Task 1–2: hand-tuning" });
s = content("Task 1 — Baseline CNN", "Task 1–2: hand-tuning");
fig(s, "nb1_curves.png", { x: 0.5, y: 1.3, w: 7.6, h: 4.4 });
text(s, "Train loss keeps falling while the validation loss is minimal at epoch 6: the network **memorizes** the training set.", { x: 0.6, y: 5.85, w: 7.4, h: 0.8 }, 13, { italic: true, color: C.accent4 });
stat(s, fx(nb1.test_acc) + "%", "test accuracy", 8.5, 1.35, 2.05);
stat(s, fx(nb1.gen_gap, 1) + " pts", "generalization gap", 10.7, 1.35, 2.05);
bullets(s, [
  "3 × Conv3×3 → ReLU → MaxPool (32/64/128 ch.), FC 8192 → 256 → 10, **2.19M** params",
  "SGD momentum 0.9, lr 0.01, batch 64, 30 epochs",
  "Main confusions: Highway → River, PermanentCrop → HerbaceousVeg.",
], { x: 8.5, y: 2.9, w: 4.25, h: 3.8 }, 15);

// 4. Task 2a architecture
s = content("Task 2a — Architecture, one factor at a time", "Task 1–2: hand-tuning");
fig(s, "nb2_arch.png", { x: 0.5, y: 1.25, w: 7.6, h: 4.8 });
bullets(s, [
  "**Depth matters most**: 5 blocks → receptive field 94 px (the whole tile) and **fewer** params (1.24M vs 2.19M)",
  "**Large kernels hurt**: 7×7 → " + fx(nb2.kernel_7x7.best_val_acc) + "%",
  "Valid padding and stride-2 lose information",
  "BatchNorm: +0.8 pt, smoother training",
  "**Combined** (5 blocks, 3×3, same padding, max-pool, BN): [[" + fx(nb2.combined.best_val_acc) + "% val.]], gap halved",
], { x: 8.4, y: 1.4, w: 4.35, h: 5.3 }, 16);

// 5. Task 2b optimizers
s = content("Task 2b — Optimizers, learning rates, schedulers", "Task 1–2: hand-tuning");
fig(s, "nb3_optim.png", { x: 0.5, y: 1.25, w: 7.6, h: 4.5 });
text(s, "Left: peak validation accuracy (%) per optimizer and learning rate. Right: Adam lr 1e-3 with each scheduler.", { x: 0.6, y: 5.85, w: 7.4, h: 0.7 }, 12, { italic: true, color: C.accent4 });
bullets(s, [
  "3 optimizers × 3 learning rates, 25 epochs",
  "**lr 1e-3 best for all**; 1e-2 unstable for Adam/AdamW, 1e-4 too slow for SGD",
  "Adam 1e-3: best and fastest (" + fx(nb3["Adam_lr0.001"].best_val_acc) + "%)",
  "Schedulers add **+1.4–1.7 pts**: small steps at the end remove the oscillations",
  "Recipe Adam + StepLR: [[96.22% test]]",
], { x: 8.4, y: 1.4, w: 4.35, h: 5.3 }, 16);

// 6. Task 2c augmentation
s = content("Task 2c — Data augmentation", "Task 1–2: hand-tuning");
fig(s, "aug_examples.png", { x: 0.5, y: 1.3, w: 6.0, h: 1.5 });
bullets(s, [
  "No \"up\" in satellite images: **vertical flips and 90° rotations keep the label**",
  "Color carries the class → weak color jitter only",
  "MixUp / CutMix written by hand:",
], { x: 0.6, y: 3.05, w: 5.9, h: 1.6 }, 16);
s.addShape(pres.ShapeType.roundRect, { x: 0.6, y: 4.6, w: 5.9, h: 0.6, rectRadius: 0.08, fill: { color: C.background2 }, line: { color: C.background2 }, objectName: "loss code" });
s.addText("loss = lam*CE(out, y_a) + (1-lam)*CE(out, y_b)", { x: 0.7, y: 4.6, w: 5.7, h: 0.6, isTextBox: true, fontFace: "Courier New", fontSize: 14, color: C.text1, margin: 0, valign: "middle" });
text(s, "Gap measured on **clean** training images: " + fx(nb4.none.gen_gap, 1) + " → ≈1 pt. Affine creates black corners; CutMix needs longer training.", { x: 0.6, y: 5.45, w: 5.9, h: 0.9 }, 15);
fig(s, "nb4_aug.png", { x: 6.8, y: 1.25, w: 6.0, h: 4.7 });
text(s, "Best: flips + crop + MixUp → [[" + fx(b4.test_acc) + "% test]]", { x: 6.9, y: 6.1, w: 5.8, h: 0.5 }, 17, { align: "center" });

// 7. Task 2 comparison table
s = content("Task 2 — Comparison table (selection)", "Task 1–2: hand-tuning");
const hdr = ["NB", "Configuration", "Params", "Latency (ms)", "Peak val. (%)", "Gap (pts)"];
const rowsA = [["NB2", "baseline", nb2.baseline], ["NB2", "2 blocks", nb2.depth_2blocks], ["NB2", "5 blocks", nb2.depth_5blocks],
  ["NB2", "7×7 kernels", nb2.kernel_7x7], ["NB2", "stride-2", nb2.downsample_stride], ["NB2", "BatchNorm", nb2.batchnorm], ["NB2", "combined", nb2.combined]]
  .map(([nb, n, x]) => [nb, n, M(x.params), fx(x.latency_ms, 3), fx(x.best_val_acc), fx(x.gen_gap)]);
const rowsB = [["NB3", "SGD lr 1e-2", nb3["SGD_lr0.01"]], ["NB3", "Adam lr 1e-3", nb3["Adam_lr0.001"]], ["NB3", "Adam + StepLR", nb3["Adam_lr0.001_StepLR"]],
  ["NB4", "no augmentation", nb4.none], ["NB4", "flips + crop", nb4.flips_crop], ["NB4", "+ MixUp", nb4.flips_crop_mixup], ["NB4", "+ CutMix", nb4.flips_crop_cutmix]]
  .map(([nb, n, x]) => [nb, n, M(b4.params), fx(b4.latency_ms, 3), fx(x.best_val_acc), fx(x.gen_gap)]);
table(s, [hdr, ...rowsA], { x: 0.6, y: 1.4, w: 5.9, colW: [0.55, 1.45, 0.8, 1.05, 1.1, 0.95] }, { fontSize: 13, rowH: 0.4, highlight: [7], leftCols: 1 });
table(s, [hdr, ...rowsB], { x: 6.85, y: 1.4, w: 5.9, colW: [0.55, 1.45, 0.8, 1.05, 1.1, 0.95] }, { fontSize: 13, rowH: 0.4, highlight: [6], leftCols: 1 });
text(s, "Latency: one image on a T4 GPU. Gap: train − validation accuracy at the best epoch (NB4: clean training images). The full table (31 runs) is in the report.", { x: 0.6, y: 4.95, w: 12.1, h: 0.4 }, 13, { italic: true, color: C.accent4 });
stat(s, "90.15 → 95.36%", "architecture (NB2)", 0.6, 5.5, 3.85);
stat(s, "96.22%", "+ Adam & StepLR (NB3)", 4.75, 5.5, 3.85);
stat(s, fx(b4.test_acc) + "%", "+ augmentation & MixUp (NB4)", 8.9, 5.5, 3.85);

// 8. Task 3
pres.addSection({ title: "Task 3: transfer learning" });
s = content("Task 3 — Transfer learning with ResNet-18", "Task 3: transfer learning");
fig(s, "nb5_transfer.png", { x: 0.5, y: 1.2, w: 7.2, h: 3.95 });
const tl = [["Test acc. (%)", "5%", "10%", "25%", "100%"],
  ...[["scratch", "Scratch CNN"], ["frozen", "ResNet frozen"], ["partial", "ResNet layer4"], ["full", "ResNet full"]]
    .map(([k, n]) => [n, ...[5, 10, 25, 100].map((f) => fx(nb5[k + "_" + f + "pct"].test_acc))])];
table(s, tl, { x: 0.8, y: 5.25, w: 6.6, colW: [1.8, 1.2, 1.2, 1.2, 1.2] }, { fontSize: 13, rowH: 0.3, highlight: [4] });
bullets(s, [
  "ImageNet ResNet-18, images resized to 128×128",
  "Freeze with requires_grad = False; new head Dropout → Linear(512, 10)",
  "lr 1e-4 for pretrained layers, 1e-3 for the head",
  "Full fine-tuning: [[99.04%]], and 95.95% with **5% of the data** (945 images)",
  "Converges in 1 epoch (scratch: 6)",
  "Frozen saturates at ≈90%: unfreezing layer4 recovers most of the gain",
  "Cost: 9× params, 3× latency",
], { x: 8.0, y: 1.35, w: 4.75, h: 5.4 }, 15);

// 9. NASWOT method
pres.addSection({ title: "Zero-cost NAS" });
s = content("Zero-cost NAS — NASWOT (Mellor et al., ICML 2021)", "Zero-cost NAS");
bullets(s, [
  "Judge an architecture **at initialization**, on **one mini-batch**, in ≈0.1 s — no training",
  "Binary code c_i of each image: which ReLUs are active",
  "Same code = same linear region → the network cannot separate the two images",
  "High score = images well separated → the network trains well",
  "Implemented with **forward hooks** on every nn.ReLU",
  "Compared with SynFlow, SNIP, grad-norm and #params",
], { x: 0.6, y: 1.35, w: 5.9, h: 2.85 }, 16);
s.addShape(pres.ShapeType.roundRect, { x: 0.6, y: 4.3, w: 5.9, h: 1.25, rectRadius: 0.1, fill: { color: C.background2 }, line: { color: C.background2 }, objectName: "formula card" });
s.addText([
  { text: "K_H[i, j] = N_A − d_H(c_i, c_j)", options: { breakLine: true } },
  { text: "score  s = log |K_H|" },
], { x: 0.8, y: 4.35, w: 5.5, h: 1.15, isTextBox: true, fontFace: "Cambria", fontSize: 20, italic: true, color: C.accent1, align: "center", valign: "middle", margin: 0 });
const code = [
  "def naswot_score(net, inputs):",
  "    B = inputs.size(0)",
  "    K = torch.zeros(B, B, dtype=torch.float64)",
  "    def hook(module, inp, out):",
  "        x = (inp[0].view(B, -1) > 0).double()",
  "        K.add_(x @ x.t() + (1-x) @ (1-x).t())",
  "    for m in net.modules():",
  "        if isinstance(m, nn.ReLU):",
  "            m.register_forward_hook(hook)",
  "    with torch.no_grad():",
  "        net(inputs)",
  "    return torch.linalg.slogdet(K)[1]",
];
s.addShape(pres.ShapeType.roundRect, { x: 6.85, y: 1.35, w: 5.9, h: 4.2, rectRadius: 0.1, fill: { color: "1F2A24" }, line: { color: "1F2A24" }, objectName: "code card" });
s.addText(code.map((l, k) => ({ text: l, options: { breakLine: k < code.length - 1 } })),
  { x: 7.05, y: 1.5, w: 5.55, h: 3.9, isTextBox: true, fontFace: "Courier New", fontSize: 14, color: C.background1, margin: 0, valign: "middle" });
text(s, "Simplified from NB6.1", { x: 6.85, y: 5.6, w: 5.9, h: 0.35 }, 12, { italic: true, color: C.accent4, align: "right" });

// 10. reproduction
s = content("Step 1 — Reproducing the paper on NAS-Bench-201", "Zero-cost NAS");
fig(s, "nb61_scatter.png", { x: 0.5, y: 1.3, w: 4.2, h: 4.7 });
text(s, "15,625 networks with **known** trained accuracy. Our re-implementation has **exactly the official number of parameters** for 300/300 architectures.", { x: 0.6, y: 6.0, w: 4.1, h: 0.85 }, 13);
const t = rep.kendall_tau;
table(s, [["Kendall τ", "CIFAR-10", "CIFAR-100", "ImageNet16-120*"],
  ["ours", fx(t.cifar10.ours, 3), fx(t.cifar100.ours, 3), fx(t.imagenet16.ours, 3)],
  ["paper", fx(t.cifar10.paper, 3), fx(t.cifar100.paper, 3), fx(t.imagenet16.paper, 3)]],
  { x: 5.0, y: 1.35, w: 7.75, colW: [2.35, 1.8, 1.8, 1.8] }, { fontSize: 14, rowH: 0.36, highlight: [1] });
const srows = [["Search, test acc. (%)", "CIFAR-10", "CIFAR-100", "ImageNet16-120*"]];
const hlRows = [];
["NASWOT (N=10)", "NASWOT (N=100)", "Random"].forEach((k) => {
  const x = rep.search[k];
  hlRows.push(srows.length);
  srows.push([k + " — ours", ...[1, 3, 5].map((i) => fx(x.ours_mean[i]) + " ± " + fx(x.ours_std[i]))]);
  srows.push([k + " — paper", ...[1, 3, 5].map((i) => fx(x.paper[i][0]) + " ± " + fx(x.paper[i][1]))]);
});
table(s, srows, { x: 5.0, y: 2.75, w: 7.75, colW: [2.35, 1.8, 1.8, 1.8] }, { fontSize: 14, rowH: 0.36, highlight: hlRows });
s.addShape(pres.ShapeType.roundRect, { x: 5.0, y: 5.65, w: 7.75, h: 0.8, rectRadius: 0.1, fill: { color: C.background2 }, line: { color: C.background2 }, objectName: "verdict" });
text(s, "NASWOT search matches Table 2 of the paper within ≈0.1 pt → **our implementation is correct**", { x: 5.2, y: 5.65, w: 7.35, h: 0.8 }, 17, { valign: "middle", color: C.accent1 });
text(s, "* ImageNet16-120 is not on Kaggle: scored with CIFAR-100 images at 16×16.", { x: 5.0, y: 6.55, w: 7.75, h: 0.35 }, 11, { italic: true, color: C.accent4 });

// 11. NAS on EuroSAT
s = content("Step 2 — Zero-cost NAS on EuroSAT", "Zero-cost NAS");
bullets(s, [
  "Search space = the Task 2 knobs: 2–5 blocks, kernel 3/5/7 **per block**, width 16/32/64, BN, pool/stride, skip → **8,640 CNNs**",
  "51 networks trained 5 epochs to check the proxies (Spearman ρ):",
], { x: 0.6, y: 1.35, w: 6.4, h: 1.5 }, 16);
table(s, [["", "NASWOT", "SynFlow", "SNIP", "grad-norm", "#params"],
  ["ρ", ...["naswot", "synflow", "snip", "grad_norm", "params"].map((p) => fx(corr[p][0]))]],
  { x: 0.9, y: 2.8, w: 5.9, colW: [0.5, 1.1, 1.1, 1.0, 1.1, 1.1] }, { fontSize: 14, rowH: 0.36 });
bullets(s, [
  "Search: 1000 networks scored in " + fx(nas.scoring_time_s, 0) + " s, then the top-3 trained",
  "NASWOT top-3: **90.8%** mean (5 epochs) vs random 83.3%, hand-designed 87.7%",
], { x: 0.6, y: 3.7, w: 6.4, h: 1.3 }, 16);
const hd = nas.final.hand_designed, nw = nas.final.nas_winner;
table(s, [["Full recipe", "Test acc.", "Params", "Latency", "Search GPU"],
  ["Hand-designed", fx(hd.test_acc) + "%", M(hd.params), fx(hd.latency_ms) + " ms", fx(nas.manual_time_s / 60, 0) + " min"],
  ["NAS winner", fx(nw.test_acc) + "%", M(nw.params), fx(nw.latency_ms) + " ms", fx(nas.nas_time_s / 60, 0) + " min"]],
  { x: 0.6, y: 5.3, w: 6.4, colW: [1.6, 1.2, 1.1, 1.2, 1.3] }, { fontSize: 14, rowH: 0.36, highlight: [2] });
fig(s, "nb62_scatter.png", { x: 7.4, y: 1.25, w: 5.3, h: 4.55 });
text(s, "Winner: 5 blocks, kernels 5-3-3-3-3, width 64, BN, max-pool, **residual** → better than our design with **12× less GPU time**", { x: 7.5, y: 5.9, w: 5.2, h: 0.9 }, 14);

// 12. final comparison — accuracy vs latency
pres.addSection({ title: "Results and conclusion" });
s = content("Final comparison — all 50 checkpoints (NB7)", "Results and conclusion");
fig(s, "nb7_pareto.png", { x: 0.5, y: 1.2, w: 7.3, h: 5.5 });
const fin = [["Model", "Test acc.", "F1", "Params", "Latency"],
  ...[["Baseline", "NB1_baseline_sgd_lr0.01_bs64_30ep"], ["Hand-designed", "NB4_flips_crop_mixup"], ["NAS winner", "NB6_2_nas_winner"], ["ResNet-18 FT", "NB5_full_100pct"]]
    .map(([n, k]) => [n, fx(m7[k].test_acc), fx(m7[k].test_f1_macro), M(m7[k].params), fx(m7[k].latency_ms) + " ms"])];
table(s, fin, { x: 8.05, y: 1.4, w: 4.7, colW: [1.35, 0.85, 0.75, 0.8, 0.95] }, { fontSize: 13, rowH: 0.4 });
bullets(s, [
  "Every checkpoint re-evaluated on the same 4,050 test images",
  "Trade-off: the NAS winner is 1.6× slower than the hand-designed CNN, ResNet-18 3× slower",
  "ResNet-18 is the most accurate, the scratch CNNs the fastest",
], { x: 8.05, y: 3.75, w: 4.7, h: 3.0 }, 15);

// 13. errors
s = content("Where do the models still fail?", "Results and conclusion");
fig(s, "nb7_confusion.png", { x: 0.5, y: 1.2, w: 8.3, h: 5.6 });
stat(s, "120", "errors — hand-designed CNN", 9.15, 1.35, 3.6);
stat(s, "39", "errors — ResNet-18 fine-tuned", 9.15, 2.8, 3.6);
bullets(s, [
  "Remaining errors: agricultural classes (PermanentCrop / HerbaceousVeg. / AnnualCrop / Pasture)",
  "ResNet makes **different** mistakes from the scratch CNNs",
  "14 images wrong for all models: mixed land uses",
], { x: 9.15, y: 4.35, w: 3.6, h: 2.5 }, 14);

// 14. conclusions
s = content("Conclusions", "Results and conclusion");
stat(s, "90.15 → " + fx(b4.test_acc) + "%", "hand-tuning a CNN from scratch", 0.6, 1.35, 3.85);
stat(s, "99.04%", "fine-tuned ResNet-18 (95.95% with 5% of the data)", 4.75, 1.35, 3.85);
stat(s, fx(nw.test_acc) + "%", "zero-cost NAS, 17 GPU-min vs 203", 8.9, 1.35, 3.85);
s.addText("Findings", { x: 0.6, y: 2.95, w: 5.9, h: 0.45, isTextBox: true, fontFace: "Cambria", fontSize: 20, bold: true, color: C.accent1, margin: 0.05 });
bullets(s, [
  "Depth and small kernels, Adam with a decaying lr, orientation-invariant augmentation",
  "Transfer learning is the most accurate and by far the best with little data — at 9× the size",
  "Zero-cost NAS **reproduced** on NAS-Bench-201, then found a CNN **better than ours**",
], { x: 0.6, y: 3.45, w: 5.9, h: 3.3 }, 16);
s.addText("Limitations", { x: 6.85, y: 2.95, w: 5.9, h: 0.45, isTextBox: true, fontFace: "Cambria", fontSize: 20, bold: true, color: C.accent1, margin: 0.05 });
bullets(s, [
  "One seed per configuration; repeated runs vary by ≈0.3–1 pt → only large effects are conclusive",
  "EuroSAT NAS ground truth = a 5-epoch training",
  "ImageNet16 scored with substitute images",
  "**Live demo (NB7)**: load any checkpoint, classify an image, change lr / activation / loss / augmentation and retrain in seconds",
], { x: 6.85, y: 3.45, w: 5.9, h: 3.3 }, 16);

// 15. thank you
s = pres.addSlide({ masterName: "TITLE", sectionTitle: "Results and conclusion" });
s.addImage({ path: LOGO, x: 11.3, y: 0.6, w: 1.4, h: 1.41, objectName: "logo" });
s.addText("Thank you — questions?", { placeholder: "title" });
s.addText("Notebooks NB0–NB7 · 50 checkpoints · report and figures generated from the saved results", { placeholder: "body" });
s.addText("Emilio Yared  ·  Joe Missisian  —  Group 7", { x: 0.8, y: 5.4, w: 10, h: 0.5, isTextBox: true, fontSize: 16, bold: true, color: C.background1, margin: 0 });

// ---------------------------------------------------------------- write
(async () => {
  await pres.writeFile({ fileName: OUT });
  const { applyTheme } = require(process.env.APPLY_THEME);
  await applyTheme(OUT, THEME);
  console.log("written", OUT);
})();
