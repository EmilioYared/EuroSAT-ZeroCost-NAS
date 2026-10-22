"""New figures for the English report (search-strategy comparison, cell diagram, pipeline)."""
import json
import numpy as np
import pandas as pd
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch, FancyArrowPatch

OUT = "figures/"
plt.rcParams.update({"font.family": "serif", "font.serif": ["Times New Roman", "DejaVu Serif"], "font.size": 14,
                     "axes.titlesize": 15, "axes.labelsize": 14, "legend.fontsize": 12, "xtick.labelsize": 12,
                     "ytick.labelsize": 12, "savefig.dpi": 300, "savefig.bbox": "tight"})
GREEN, GREY = "#13613F", "#8C9A92"
PAL = ["#13613F", "#2F6DB5", "#C77C02", "#7A4EAB", "#1A9E9E", "#555555"]
d = json.load(open("experiments/nas_comparison.json"))

# 1. anytime curves -------------------------------------------------------------------
fig, ax = plt.subplots(figsize=(9, 5.2))
x = np.arange(1, len(next(iter(d["curves"].values()))["mean"]) + 1)
for (name, c), col in zip(d["curves"].items(), PAL):
    m, s = np.array(c["mean"]), np.array(c["std"]) / np.sqrt(d["runs"])
    ax.plot(x, m, color=col, lw=2.2, label=name)
    ax.fill_between(x, m - 2 * s, m + 2 * s, color=col, alpha=0.15)
for n, ls in [("100", ":"), ("1000", "--")]:
    ax.axhline(d["naswot"][n]["mean"][1], color="black", ls=ls, lw=1.6, label="NASWOT (N=%s), no training" % n)
ax.axhline(d["best_in_space"][1], color=GREY, lw=1.2, label="Best architecture in the space")
ax.set_xscale("log"); ax.set_xlim(5, 300); ax.set_ylim(91.5, 94.6)
ax.set_xlabel("Number of architectures trained (search budget)"); ax.set_ylabel("CIFAR-10 test accuracy (%)")
ax.grid(alpha=0.3); ax.legend(loc="lower right", ncol=1, framealpha=0.95)
fig.savefig(OUT + "en_anytime.png"); plt.close(fig)

# 2. accuracy vs search cost, published results (Mellor et al., 2021, Table 2) ----------
pub = [("REA", 12000, 93.92, "nws"), ("RS", 12000, 93.70, "nws"), ("REINFORCE", 12000, 93.85, "nws"),
       ("BOHB", 12000, 93.61, "nws"), ("RSPS", 7587, 87.66, "ws"), ("DARTS-V1", 10890, 54.30, "ws"),
       ("DARTS-V2", 29902, 54.30, "ws"), ("GDAS", 28926, 93.51, "ws"), ("SETN", 31010, 86.19, "ws"),
       ("ENAS", 13315, 54.30, "ws"), ("NASWOT N=10", 3.05, 92.44, "tf"), ("NASWOT N=100", 30.01, 92.81, "tf"),
       ("NASWOT N=1000", 306.19, 92.96, "tf")]
fam = {"nws": ("Training-based search", PAL[1], "o"), "ws": ("Weight sharing", PAL[2], "s"), "tf": ("Training-free", GREEN, "D")}
fig, ax = plt.subplots(figsize=(9, 5.2))
for f, (lab, col, mk) in fam.items():
    pts = [p for p in pub if p[3] == f]
    ax.scatter([p[1] for p in pts], [p[2] for p in pts], s=90, color=col, marker=mk, label=lab, zorder=3)
labels = [("REA, RS, REINFORCE, BOHB", 12000, 93.7, (15, 12)), ("GDAS", 28926, 93.51, (-15, -20)),
          ("RSPS", 7587, 87.66, (-48, -5)), ("SETN", 31010, 86.19, (-15, -22)),
          ("DARTS-V1, ENAS", 11800, 54.3, (-150, 8)), ("DARTS-V2", 29902, 54.3, (-30, 12)),
          ("NASWOT N=10", 3.05, 92.44, (-30, -24)), ("NASWOT N=100", 30.01, 92.81, (-40, -24)), ("NASWOT N=1000", 306.19, 92.96, (-45, -24))]
for name, t, a, o in labels:
    ax.annotate(name, (t, a), xytext=o, textcoords="offset points", fontsize=12, ha="right" if name.startswith("REA") else "left")
ax.set_xscale("log"); ax.set_xlim(1, 1e5); ax.set_ylim(50, 98)
ax.set_xlabel("Search time on one GPU (s, log scale)"); ax.set_ylabel("CIFAR-10 test accuracy (%)")
ax.grid(alpha=0.3); ax.legend(loc="center right")
fig.savefig(OUT + "en_cost.png"); plt.close(fig)

# 3. distribution of the space + where each method lands ------------------------------
acc = pd.read_csv("../../results/NB6_0_NASBench201_Extract/nasbench201_accuracies.csv")["cifar10_test"]
fig, ax = plt.subplots(figsize=(9, 4.6))
ax.hist(acc, bins=np.arange(10, 95.5, 1), color=GREY, alpha=0.8)
ax.set_yscale("log"); ax.set_xlim(40, 95.5)
marks = [("Random", 86.61), ("NASWOT N=100", d["naswot"]["100"]["mean"][1]), ("REA (B=100)", d["search"]["Regularised Evolution (REA)"]["100"]["mean"][1])]
for (lab, v), col in zip(marks, [PAL[2], GREEN, PAL[1]]):
    ax.axvline(v, color=col, lw=2.2)
    ax.text(v - 0.6, 3000 if lab != "NASWOT N=100" else 900, lab, color=col, rotation=90, ha="right", va="top", fontsize=12)
ax.set_xlabel("CIFAR-10 test accuracy (%)"); ax.set_ylabel("Number of architectures (log)")
ax.grid(alpha=0.3)
fig.savefig(OUT + "en_distribution.png"); plt.close(fig)

# 4. NAS-Bench-201 cell -----------------------------------------------------------------
fig, ax = plt.subplots(figsize=(8.5, 4.4))
pos = {0: (0, 0), 1: (2.2, 1.1), 2: (4.4, -1.1), 3: (6.6, 0)}
edges = [(0, 1, "conv 3×3"), (0, 2, "skip"), (1, 2, "conv 1×1"), (0, 3, "avg pool"), (1, 3, "none"), (2, 3, "conv 3×3")]
for a, b, lab in edges:
    rad = 0.8 if (a, b) == (0, 3) else 0.0
    ax.add_patch(FancyArrowPatch(pos[a], pos[b], arrowstyle="-|>", mutation_scale=18, lw=1.8, color="#9DBCE6",
                                 connectionstyle="arc3,rad=%.2f" % rad, shrinkA=22, shrinkB=22))
    mx, my = (pos[a][0] + pos[b][0]) / 2, (pos[a][1] + pos[b][1]) / 2
    if (a, b) == (0, 3):
        my -= 2.75
    dx, dy = {(0, 1): (-0.45, 0.35), (1, 2): (0.75, 0.2), (2, 3): (0.35, -0.65), (0, 2): (0, -0.45), (1, 3): (0, 0.3), (0, 3): (0, 0)}[(a, b)]
    ax.text(mx + dx, my + dy, lab, ha="center", fontsize=12)
for k, (px, py) in pos.items():
    ax.add_patch(plt.Circle((px, py), 0.42, color=GREEN))
    ax.text(px, py, "node %d" % k if k else "input", color="white", ha="center", va="center", fontsize=11)
ax.text(pos[3][0] + 0.75, pos[3][1] + 0.3, "output", ha="center", fontsize=11)
ax.set_xlim(-0.8, 7.9); ax.set_ylim(-3.2, 1.9); ax.axis("off"); ax.set_aspect("equal")
fig.savefig(OUT + "en_cell.png"); plt.close(fig)

# 5. methodology pipeline ---------------------------------------------------------------
fig, ax = plt.subplots(figsize=(11, 2.4))
steps = [("EuroSAT RGB\n27,000 images", "Fixed split\n70/15/15 %"), ("Approach 1\nHand-designed CNN", "Tasks 1–2"),
         ("Approach 2\nTransfer learning", "ResNet-18"), ("Approach 3\nZero-cost NAS", "NASWOT"),
         ("Common test set\n4,050 images", "NB7")]
for k, (t, s) in enumerate(steps):
    x0 = k * 2.05
    ax.add_patch(FancyBboxPatch((x0, 0), 1.75, 1.3, boxstyle="round,pad=0.05,rounding_size=0.15",
                                fc=GREEN if k in (0, 4) else "#EEF4F0", ec=GREEN, lw=1.6))
    ax.text(x0 + 0.875, 0.85, t, ha="center", va="center", fontsize=11, color="white" if k in (0, 4) else "black", weight="bold")
    ax.text(x0 + 0.875, 0.2, s, ha="center", va="center", fontsize=10.5, color="white" if k in (0, 4) else "#333333")
    if k < len(steps) - 1:
        ax.add_patch(FancyArrowPatch((x0 + 1.8, 0.65), (x0 + 2.0, 0.65), arrowstyle="-|>", mutation_scale=15, lw=1.6, color=GREY))
ax.set_xlim(-0.1, 10.15); ax.set_ylim(-0.15, 1.45); ax.axis("off")
fig.savefig(OUT + "en_pipeline.png"); plt.close(fig)

# 6. small budget: AREA vs REA vs RS ----------------------------------------------------
fig, ax = plt.subplots(figsize=(9, 4.6))
names = ["Random Search (RS)", "Regularised Evolution (REA)", "Local Search (LS)", "REINFORCE", "Assisted REA (AREA)"]
bud = ["10", "25", "50", "100"]
w = 0.16
for k, (n, col) in enumerate(zip(names, PAL)):
    m = [d["search"][n][b]["mean"][1] for b in bud]
    ax.bar(np.arange(len(bud)) + (k - 2) * w, m, w, color=col, label=n)
ax.set_xticks(range(len(bud))); ax.set_xticklabels(["B = " + b for b in bud])
ax.set_ylim(92, 94.5); ax.set_ylabel("CIFAR-10 test accuracy (%)"); ax.grid(axis="y", alpha=0.3)
ax.legend(ncol=2, loc="upper left", fontsize=11)
fig.savefig(OUT + "en_budget.png"); plt.close(fig)
print("figures written")
