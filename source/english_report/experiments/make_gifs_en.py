"""Looping GIFs for the English presentation (they play continuously in PowerPoint).
The first frame of each GIF is the complete picture, because that is what a PDF export shows."""
import io
import json
import os
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from PIL import Image, ImageDraw, ImageFont

OUT = "figures/"
DATA = "../../data/EuroSAT_RGB/"
plt.rcParams.update({"font.family": "serif", "font.serif": ["Times New Roman", "DejaVu Serif"], "font.size": 17,
                     "axes.labelsize": 18, "legend.fontsize": 14, "xtick.labelsize": 15, "ytick.labelsize": 15})
GREEN, GREY = "#13613F", "#8C9A92"
PAL = ["#13613F", "#2F6DB5", "#C77C02", "#7A4EAB", "#1A9E9E", "#555555"]
CLASSES = sorted(os.listdir(DATA))
rng = np.random.default_rng(0)


def grab(fig, dpi=100):
    buf = io.BytesIO()
    fig.savefig(buf, format="png", dpi=dpi, facecolor="white")
    buf.seek(0)
    return Image.open(buf).convert("RGB")


def save(frames, durations, name):
    pal = [f.convert("P", palette=Image.ADAPTIVE, colors=255) for f in frames]
    pal[0].save(OUT + name, save_all=True, append_images=pal[1:], duration=durations, loop=0, optimize=True)
    print(name, len(frames), "frames", os.path.getsize(OUT + name) // 1024, "KB")


# 1. EuroSAT classes: every tile cycles through real images of its class -----------------
T, PAD, LAB = 150, 14, 40
font = ImageFont.truetype("C:/Windows/Fonts/times.ttf", 25)
files = {c: [DATA + c + "/" + f for f in rng.choice(sorted(os.listdir(DATA + c)), 6, replace=False)] for c in CLASSES}
tiles = {c: [Image.open(f).convert("RGB").resize((T, T), Image.BICUBIC) for f in fs] for c, fs in files.items()}
names = {"HerbaceousVegetation": "Herbaceous", "PermanentCrop": "Perm. crop", "AnnualCrop": "Annual crop"}
W = len(CLASSES) * (T + PAD) - PAD


def classes_frame(k, alpha):
    im = Image.new("RGB", (W, T + LAB), "white")
    dr = ImageDraw.Draw(im)
    for i, c in enumerate(CLASSES):
        a, b = tiles[c][k % 6], tiles[c][(k + 1) % 6]
        im.paste(Image.blend(a, b, alpha), (i * (T + PAD), 0))
        lab = names.get(c, c)
        dr.text((i * (T + PAD) + T / 2, T + 6), lab, fill=GREEN, font=font, anchor="ma")
    return im


frames, dur = [], []
for k in range(6):
    frames.append(classes_frame(k, 0)); dur.append(1100)
    for a in (0.25, 0.5, 0.75):
        frames.append(classes_frame(k, a)); dur.append(70)
save(frames, dur, "gif_classes.gif")

# 2. NASWOT: one batch -> binary ReLU codes -> kernel K_H -> score -----------------------
# A real (tiny) untrained ReLU layer applied to 8 real EuroSAT images.
B, U = 8, 32
imgs = [Image.open(files[c][0]).convert("RGB") for c in CLASSES[:B]]
x = np.stack([np.asarray(im.resize((16, 16)), dtype=float).ravel() / 255 for im in imgs])
x = (x - x.mean(0)) / (x.std(0) + 1e-6)
codes = (x @ rng.normal(size=(x.shape[1], U)) > 0).astype(int)
K = U - (codes[:, None, :] != codes[None, :, :]).sum(-1)
score = np.linalg.slogdet(K.astype(float))[1]


def naswot_frame(n_img, n_k, show_score):
    fig = plt.figure(figsize=(8.0, 4.4))
    gi = fig.add_axes([0.01, 0.03, 0.11, 0.84]); gc = fig.add_axes([0.17, 0.03, 0.40, 0.84]); gk = fig.add_axes([0.64, 0.2, 0.34, 0.6])
    gi.axis("off"); gi.set_xlim(0, 1); gi.set_ylim(B, 0)
    for i in range(n_img):
        gi.imshow(np.asarray(imgs[i]), extent=(0.05, 0.95, i + 0.95, i + 0.05))
    gi.set_title("Images", fontsize=19, color=GREEN)
    shown = np.full((B, U), np.nan); shown[:n_img] = codes[:n_img]
    gc.imshow(shown, cmap=matplotlib.colors.ListedColormap(["#EEF4F0", GREEN]), vmin=0, vmax=1, aspect="auto")
    gc.set_xticks([]); gc.set_yticks([]); gc.set_title("Binary code of each image", fontsize=19, color=GREEN)
    for sp in gc.spines.values(): sp.set_color(GREY)
    kk = np.full((B, B), np.nan).ravel(); kk[:n_k] = K.ravel()[:n_k]
    gk.imshow(kk.reshape(B, B), cmap="Greens", vmin=K.min() - 4, vmax=U)
    gk.set_xticks([]); gk.set_yticks([]); gk.set_title("Kernel $K_H$", fontsize=19, color=GREEN)
    for sp in gk.spines.values(): sp.set_color(GREY)
    if show_score:
        fig.text(0.81, 0.04, "score = %.1f" % score, ha="center", fontsize=21, color=GREEN, weight="bold")
    im = grab(fig); plt.close(fig)
    return im


frames, dur = [], []
for n in range(B + 1):
    frames.append(naswot_frame(n, 0, False)); dur.append(450)
for n in range(4, B * B + 1, 4):
    frames.append(naswot_frame(B, n, False)); dur.append(90)
frames.insert(0, naswot_frame(B, B * B, True)); dur.insert(0, 2600)
save(frames, dur, "gif_naswot.gif")

# 3. anytime curves drawn progressively --------------------------------------------------
d = json.load(open("experiments/nas_comparison.json"))
L = len(next(iter(d["curves"].values()))["mean"])
xs = np.arange(1, L + 1)


def anytime_frame(upto):
    fig, ax = plt.subplots(figsize=(9, 5.2))
    for (name, c), col in zip(d["curves"].items(), PAL):
        m, s = np.array(c["mean"])[:upto], np.array(c["std"])[:upto] / np.sqrt(d["runs"])
        ax.plot(xs[:upto], m, color=col, lw=2.4, label=name)
        ax.fill_between(xs[:upto], m - 2 * s, m + 2 * s, color=col, alpha=0.15)
    for n, ls in [("100", ":"), ("1000", "--")]:
        ax.axhline(d["naswot"][n]["mean"][1], color="black", ls=ls, lw=1.6, label="NASWOT (N=%s), no training" % n)
    ax.axhline(d["best_in_space"][1], color=GREY, lw=1.2, label="Best architecture in the space")
    ax.set_xscale("log"); ax.set_xlim(5, 300); ax.set_ylim(91.5, 94.6)
    ax.set_xlabel("Number of architectures trained (search budget)"); ax.set_ylabel("CIFAR-10 test accuracy (%)")
    ax.grid(alpha=0.3); ax.legend(loc="lower right", framealpha=0.95)
    fig.tight_layout()
    im = grab(fig); plt.close(fig)
    return im


steps = np.unique(np.geomspace(5, L, 36).astype(int))
frames = [anytime_frame(L)] + [anytime_frame(u) for u in steps]
dur = [3500] + [110] * len(steps)
save(frames, dur, "gif_anytime.gif")
