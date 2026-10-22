"""Builds the figures of the report from the result files saved by the notebooks (no training).

Usage (from the Report folder):  python make_figures.py          -> figures/*.pdf         (report, one IEEE column)
                                 python make_figures.py slides   -> figures_slides/*.png  (presentation, larger fonts)
Reads  ../../results/<NB>/*.json|csv
"""
import json
import os
import sys

import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

P = os.path.join("..", "..", "results")
SLIDES = len(sys.argv) > 1 and sys.argv[1] == "slides"
FIG = "figures_slides" if SLIDES else "figures"
os.makedirs(FIG, exist_ok=True)
plt.rcParams.update({"font.size": 7, "axes.titlesize": 7.5, "axes.labelsize": 7, "legend.fontsize": 6,
                     "xtick.labelsize": 6, "ytick.labelsize": 6, "font.family": "serif", "lines.linewidth": 1.1})
W1 = 3.45   # one IEEE column, inches
FS = 1.0    # factor for the fixed font sizes below
HS = 1.35   # height factor: taller figures, less condensed
if SLIDES:
    # same figures drawn at 1.75x the size: the fonts keep their size in points, so they look larger on a slide
    W1, HS, FS = 3.45 * 1.75, 1.35 * 1.75, 1.6
    plt.rcParams.update({"font.size": 11, "axes.titlesize": 12, "axes.labelsize": 11, "legend.fontsize": 9.5,
                         "xtick.labelsize": 9.5, "ytick.labelsize": 9.5, "lines.linewidth": 1.6})


def res(nb, name):
    return os.path.join(P, nb, name)


def load(nb, name):
    with open(res(nb, name)) as f:
        return json.load(f)


def save(fig, name):
    fig.tight_layout(pad=0.3)
    if SLIDES:
        name = name.replace(".pdf", ".png")
    fig.savefig(os.path.join(FIG, name), bbox_inches="tight", dpi=300)
    plt.close(fig)
    print("saved", name)


# ---- 1. NB1 learning curves -------------------------------------------------
h = load("NB1_Baseline_CNN", "NB1_baseline_sgd_lr0.01_bs64_30ep_history.json")
ep = np.arange(1, len(h["val_acc"]) + 1)
fig, (a1, a2) = plt.subplots(1, 2, figsize=(W1, 1.45 * HS))
a1.plot(ep, h["train_loss"], label="train"); a1.plot(ep, h["val_loss"], label="validation")
a1.set_xlabel("epoch"); a1.set_ylabel("cross-entropy"); a1.legend(); a1.grid(alpha=.3)
a2.plot(ep, h["train_acc"], label="train"); a2.plot(ep, h["val_acc"], label="validation")
a2.set_xlabel("epoch"); a2.set_ylabel("accuracy (%)"); a2.set_ylim(40, 101); a2.grid(alpha=.3)
save(fig, "nb1_curves.pdf")

# ---- 2. NB2 architecture variations -----------------------------------------
s2 = load("NB2_Architecture_Variations", "NB2_summaries.json")["summaries"]
names = list(s2)
labels = {"baseline": "baseline", "depth_2blocks": "2 blocks", "depth_4blocks": "4 blocks", "depth_5blocks": "5 blocks",
          "fc_1layers": "1 FC", "fc_3layers": "3 FC", "kernel_5x5": "5x5 kernel", "kernel_7x7": "7x7 kernel",
          "padding_valid": "valid pad.", "downsample_stride": "stride-2", "batchnorm": "BatchNorm", "combined": "combined"}
fig, ax = plt.subplots(figsize=(W1, 1.6 * HS))
acc = [s2[n]["best_val_acc"] for n in names]
gap = [s2[n]["gen_gap"] for n in names]
x = np.arange(len(names))
b = ax.bar(x, acc, color=["tab:green" if n == "combined" else ("grey" if n == "baseline" else "tab:blue") for n in names])
ax.set_ylim(75, 97); ax.set_ylabel("best val. acc. (%)")
ax.set_xticks(x); ax.set_xticklabels([labels[n] for n in names], rotation=45, ha="right")
ax2 = ax.twinx(); ax2.plot(x, gap, "o", color="tab:red", ms=3 * FS); ax2.set_ylabel("gap (pts)", color="tab:red"); ax2.set_ylim(0, 20)
ax.axhline(s2["baseline"]["best_val_acc"], color="grey", ls=":", lw=.8)
ax.grid(axis="y", alpha=.3)
save(fig, "nb2_arch.pdf")

# ---- 3. NB3 optimizer x lr heatmap + schedulers ------------------------------
s3 = load("NB3_Optimizers_LR_Schedulers", "NB3_summaries.json")["summaries"]
opts, lrs = ["SGD", "Adam", "AdamW"], [0.01, 0.001, 0.0001]
grid = np.array([[s3["%s_lr%g" % (o, lr)]["best_val_acc"] for lr in lrs] for o in opts])
fig, (a1, a2) = plt.subplots(1, 2, figsize=(W1, 1.45 * HS), gridspec_kw={"width_ratios": [1, 1.25]})
a1.imshow(grid, cmap="Blues", vmin=89, vmax=95)
a1.set_xticks(range(3)); a1.set_xticklabels(["1e-2", "1e-3", "1e-4"]); a1.set_yticks(range(3)); a1.set_yticklabels(opts)
a1.set_xlabel("learning rate")
for i in range(3):
    for j in range(3):
        a1.text(j, i, "%.1f" % grid[i, j], ha="center", va="center", fontsize=6 * FS, color="white" if grid[i, j] > 93.5 else "black")
for sched, name in [("none", "Adam_lr0.001"), ("StepLR", "Adam_lr0.001_StepLR"), ("Cosine", "Adam_lr0.001_Cosine"), ("OneCycle", "Adam_lr0.001_OneCycle")]:
    hh = load("NB3_Optimizers_LR_Schedulers", "NB3_%s_history.json" % name)
    a2.plot(np.arange(1, 26), hh["val_acc"], label=sched)
a2.set_ylim(85, 97); a2.set_xlabel("epoch"); a2.set_ylabel("val. acc. (%)"); a2.legend(ncol=2, loc="upper left"); a2.grid(alpha=.3)
save(fig, "nb3_optim.pdf")

# ---- 4. NB4 augmentation ablation ---------------------------------------------
s4 = load("NB4_Data_Augmentation", "NB4_summaries.json")["summaries"]
order = ["none", "flips", "flips_crop", "flips_crop_affine", "flips_crop_affine_jitter", "flips_crop_mixup", "flips_crop_cutmix"]
lab4 = ["none", "+flips/rot90", "+crop", "+affine", "+jitter", "flips+crop\n+MixUp", "flips+crop\n+CutMix"]
fig, ax = plt.subplots(figsize=(W1, 1.55 * HS))
x = np.arange(len(order))
ax.bar(x, [s4[n]["best_val_acc"] for n in order], color=["grey"] + ["tab:blue"] * 4 + ["tab:green", "tab:green"])
ax.set_ylim(94.5, 97); ax.set_ylabel("best val. acc. (%)"); ax.set_xticks(x); ax.set_xticklabels(lab4, rotation=40, ha="right")
ax2 = ax.twinx(); ax2.plot(x, [s4[n]["gen_gap"] for n in order], "o-", color="tab:red", ms=3 * FS); ax2.set_ylabel("gap (pts)", color="tab:red"); ax2.set_ylim(0, 4.5)
ax.grid(axis="y", alpha=.3)
save(fig, "nb4_aug.pdf")

# ---- 5. NB5 data efficiency -----------------------------------------------------
s5 = load("NB5_Transfer_Learning", "NB5_summaries.json")["summaries"]
fr = [5, 10, 25, 100]
fig, (a1, a2) = plt.subplots(1, 2, figsize=(W1, 1.5 * HS))
for m, lab in [("scratch", "scratch CNN"), ("frozen", "ResNet frozen"), ("partial", "ResNet layer4"), ("full", "ResNet full")]:
    a1.plot(fr, [s5["%s_%dpct" % (m, f)]["test_acc"] for f in fr], "o-", ms=3 * FS, label=lab)
    hh = load("NB5_Transfer_Learning", "NB5_%s_100pct_history.json" % m)
    a2.plot(np.arange(1, len(hh["val_acc"]) + 1), hh["val_acc"], label=lab)
a1.set_xscale("log"); a1.set_xticks(fr); a1.set_xticklabels(["5%", "10%", "25%", "100%"]); a1.minorticks_off()
a1.set_xlabel("training data"); a1.set_ylabel("test acc. (%)"); a1.grid(alpha=.3); a1.legend()
a2.set_xlabel("epoch (100% data)"); a2.set_ylabel("val. acc. (%)"); a2.set_ylim(80, 100); a2.grid(alpha=.3)
save(fig, "nb5_transfer.pdf")

# ---- 6. NB6.1 NAS-Bench-201 score vs accuracy -------------------------------------
import csv
rows = list(csv.DictReader(open(res("NB6_1_NASBench201_Reproduction", "NB6_1_nasbench201_naswot_scores.csv"))))
sc = np.array([float(r["naswot_cifar10"]) for r in rows]); va = np.array([float(r["cifar10_valid"]) for r in rows])
ok = (sc > 0) & (va > 50)
fig, ax = plt.subplots(figsize=(W1 * 0.5, 1.5 * HS))
ax.hexbin(va[ok], sc[ok], gridsize=40, bins="log", cmap="Blues", mincnt=1, linewidths=0)
ax.set_xlabel("CIFAR-10 val. acc. (%)"); ax.set_ylabel("NASWOT score"); ax.set_title("NAS-Bench-201, 15,625 archs")
save(fig, "nb61_scatter.pdf")

# ---- 7. NB6.2 EuroSAT: NASWOT vs short-training accuracy ---------------------------
r62 = load("NB6_2_EuroSAT_ZeroCost_NAS", "NB6_2_correlation_study.json")
st = r62["study"]
fig, ax = plt.subplots(figsize=(W1 * 0.5, 1.5 * HS))
ax.scatter([s["naswot"] for s in st[:-1]], [s["short_val_acc"] for s in st[:-1]], s=6 * FS, alpha=.7, label="random")
ax.scatter([st[-1]["naswot"]], [st[-1]["short_val_acc"]], s=40, marker="*", color="red", label="hand-designed")
nas = load("NB6_2_EuroSAT_ZeroCost_NAS", "NB6_2_nas_results.json")
top = [r for r in nas["search_results"] if r["method"] == "NASWOT top-3"]
ax.scatter([r["naswot"] for r in top], [r["short_val_acc"] for r in top], s=12, marker="D", color="tab:green", label="NASWOT top-3")
ax.set_xlabel("NASWOT score (init.)"); ax.set_ylabel("val. acc., 5 ep. (%)"); ax.set_title("EuroSAT search space")
ax.set_xlim(1100, 1560); ax.legend(loc="lower right", framealpha=0.9); ax.grid(alpha=.3)
save(fig, "nb62_scatter.pdf")

# ---- 8. NB7 final: accuracy vs latency -----------------------------------------------
nb7 = os.path.join(P, "NB7_Final_Evaluation", "NB7_master_results.json")
if os.path.exists(nb7):
    m = json.load(open(nb7))["models"]
    colors = {"NB1": "black", "NB2": "tab:blue", "NB3": "tab:purple", "NB4": "tab:cyan", "NB5": "tab:orange", "NB6.2": "tab:green"}
    fig, ax = plt.subplots(figsize=(W1, 1.8 * HS))
    for nb, c in colors.items():
        sel = [k for k in m if m[k]["notebook"] == nb and m[k]["test_acc"] > 85]
        ax.scatter([m[k]["latency_ms"] for k in sel], [m[k]["test_acc"] for k in sel], s=10 * FS, c=c, label=nb, alpha=.8)
    for k, lab in [("NB1_baseline_sgd_lr0.01_bs64_30ep", "baseline"), ("NB4_flips_crop_mixup", "hand-designed"),
                   ("NB6_2_nas_winner", "NAS winner"), ("NB5_full_100pct", "ResNet-18 FT")]:
        off = {"ResNet-18 FT": (-48, 2), "hand-designed": (-52, 3), "NAS winner": (4, 3)}.get(lab, (4, -6))
        ax.annotate(lab, (m[k]["latency_ms"], m[k]["test_acc"]), textcoords="offset points", xytext=off, fontsize=6 * FS,
                    arrowprops=dict(arrowstyle="-", lw=0.4))
    ax.set_ylim(top=100); ax.set_xscale("log"); ax.set_xlabel("latency, batch 1, T4 GPU (ms)"); ax.set_ylabel("test acc. (%)"); ax.grid(alpha=.3)
    ax.legend(ncol=3, loc="lower right")
    save(fig, "nb7_pareto.pdf")
else:
    print("NB7 results not available yet")

# ---- 9. NB7 confusion matrices: hand-designed CNN vs fine-tuned ResNet-18 ----------
if os.path.exists(nb7):
    d = json.load(open(nb7))
    y = np.array(d["labels"])
    classes = json.load(open(os.path.join(P, "splits.json")))["classes"]
    short = ["AnnCrop", "Forest", "HerbVeg", "Highway", "Industr", "Pasture", "PermCrop", "Resid", "River", "SeaLake"]
    fig, axes = plt.subplots(1, 2, figsize=(W1, 1.85 * HS))
    for ax, k, title in [(axes[0], "NB4_flips_crop_mixup", "hand-designed CNN"), (axes[1], "NB5_full_100pct", "ResNet-18 fine-tuned")]:
        p = np.array(d["models"][k]["preds"])
        cm = np.zeros((10, 10))
        for t, q in zip(y, p):
            cm[t, q] += 1
        cm = cm / cm.sum(axis=1, keepdims=True)
        ax.imshow(cm, cmap="Blues", vmin=0, vmax=0.1)        # saturated at 10% to make the errors visible
        for i in range(10):
            for j in range(10):
                if i != j and cm[i, j] >= 0.01:
                    ax.text(j, i, "%d" % round(100 * cm[i, j]), ha="center", va="center", fontsize=4.5 * FS, color="white" if cm[i, j] > 0.05 else "black")
        ax.set_xticks(range(10)); ax.set_xticklabels(short, rotation=90, fontsize=4.5 * FS)
        ax.set_yticks(range(10)); ax.set_yticklabels(short if ax is axes[0] else [], fontsize=4.5 * FS)
        ax.set_title("%s (%.2f%%)" % (title, d["models"][k]["test_acc"]), fontsize=6 * FS)
        ax.set_xlabel("predicted", fontsize=5.5 * FS)
    axes[0].set_ylabel("true", fontsize=5.5 * FS)
    save(fig, "nb7_confusion.pdf")

# ---- 10. one example per class + the augmentations that keep the label --------------
from PIL import Image
root = os.path.join("..", "..", "data", "EuroSAT_RGB")
cls = sorted(os.listdir(root))
fig, axes = plt.subplots(2, 10, figsize=(2 * W1, 1.55 * HS))
for k, c in enumerate(cls):
    files = sorted(os.listdir(os.path.join(root, c)))
    for r in range(2):
        img = Image.open(os.path.join(root, c, files[r * 7]))
        axes[r, k].imshow(img); axes[r, k].axis("off")
    axes[0, k].set_title(c.replace("HerbaceousVegetation", "HerbVeg.").replace("PermanentCrop", "PermCrop"), fontsize=6 * FS)
save(fig, "classes.pdf")

img = Image.open(os.path.join(root, "River", sorted(os.listdir(os.path.join(root, "River")))[3]))
views = [("original", img), ("h-flip", img.transpose(Image.FLIP_LEFT_RIGHT)), ("v-flip", img.transpose(Image.FLIP_TOP_BOTTOM)),
         ("rot 90", img.transpose(Image.ROTATE_90)), ("rot 15 + zoom", img.rotate(15).resize((70, 70)).crop((3, 3, 67, 67)))]
fig, axes = plt.subplots(1, len(views), figsize=(W1, 0.95 * HS))
for ax, (t, v) in zip(axes, views):
    ax.imshow(v); ax.set_title(t, fontsize=6 * FS); ax.axis("off")
save(fig, "aug_examples.pdf")
