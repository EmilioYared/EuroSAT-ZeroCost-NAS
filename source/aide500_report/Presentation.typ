// AIDE500 — Presentation deck (16:9)
// Compile from this folder:  typst compile --root ../.. --font-path fonts Presentation.typ
#set page(paper: "presentation-16-9", margin: (x: 1.6cm, top: 2.3cm, bottom: 1.2cm))
#set text(font: "TeX Gyre Termes", size: 17pt)
#show raw: set text(font: "TeX Gyre Cursor", size: 15pt)
#set table(stroke: none, inset: (x: 5pt, y: 3pt))
#show table: set text(size: 13pt)

#let accent = rgb("#1f4e79")
#let R(nb, file) = json("../../results/" + nb + "/" + file)
#let fx(x, d: 2) = {
  let s = str(calc.round(x, digits: d))
  if d == 0 { return s }
  if not s.contains(".") { s += "." }
  s + "0" * (d - s.split(".").at(1).len())
}
#let M(p) = fx(p / 1e6, d: 2) + "M"
#let slide-no = counter("slide")
#let slide(title, body) = {
  pagebreak(weak: true)
  slide-no.step()
  set page(header: [
    #set text(size: 24pt, weight: "bold", fill: accent)
    #title
    #v(-0.55em)
    #line(length: 100%, stroke: 1.2pt + accent)
  ], footer: [
    #set text(size: 10pt, fill: gray)
    AIDE500 — EuroSAT: hand-tuning, transfer learning and zero-cost NAS #h(1fr) #context slide-no.display()
  ])
  body
}
#let hl(x) = text(fill: accent, weight: "bold", x)

// ------------------------------------------------------------------ title
#page(margin: 2cm)[
  #v(2.2cm)
  #text(size: 30pt, weight: "bold", fill: accent)[From Hand-Tuning to Architecture Search]
  #v(0.2em)
  #text(size: 21pt)[CNN design, transfer learning and zero-cost NAS for satellite land-use classification (EuroSAT)]
  #v(1.2cm)
  #line(length: 40%, stroke: 1.2pt + accent)
  #v(0.4cm)
  #text(size: 17pt)[Name 1 · Name 2 — Group X \ M2 Artificial Intelligence — AIDE500 Programming for AI]
]

#slide[Problem and dataset][
  #grid(columns: (1fr, 1.25fr), gutter: 0.8cm,
    [
      #set text(size: 15.5pt)
      - *EuroSAT RGB*: 27,000 Sentinel-2 tiles, 64×64 px, 10 land-use classes
      - Fixed *stratified split* 70/15/15 \ (18,900 / 4,050 / 4,050), normalization from the train split only
      - Classes defined by *texture and color*, several are visually close (crops, vegetation, pasture)
      - *Questions*
        + How far can a CNN trained from scratch go? (Tasks 1–2)
        + What does ImageNet pretraining bring? (Task 3)
        + Can the manual design be *automated cheaply*? (zero-cost NAS)
    ],
    [
      #v(1cm)
      #image("figures/classes.pdf", width: 100%)
      #v(0.5cm)
      #set text(size: 14pt)
      All selection on the *validation* set; test set only for final numbers. 9 notebooks run on a Kaggle T4 GPU, every configuration saved as a checkpoint.
    ],
  )
]

#slide[Task 1 — Baseline CNN][
  #grid(columns: (1fr, 1.1fr), gutter: 1cm,
    [
      - 3 × `Conv3×3 → ReLU → MaxPool`, 32/64/128 channels, `x.view(-1, 128*8*8)`, FC 8192→256→10 #h(0.3em) (*2.19M* params)
      - SGD momentum 0.9, lr 0.01, batch 64, 30 epochs
      - *Test accuracy 90.15%*, peak val. 89.51%
      - Clear *overfitting*: val. loss minimal at epoch 6, train acc. → 100%, gap 10.5 pts
      - Main confusions: Highway→River (8.8%), PermanentCrop→HerbaceousVeg. (8.3%)
    ],
    [#v(0.8cm) #image("figures/nb1_curves.pdf", width: 100%)],
  )
]

#slide[Task 2a — Architecture (one factor at a time)][
  #grid(columns: (1.1fr, 1fr), gutter: 1cm,
    [#image("figures/nb2_arch.pdf", width: 100%)],
    [
      - *Depth* matters most: 5 blocks → receptive field 94 px (whole tile) and *fewer* params (1.24M vs 2.19M)
      - *Large kernels hurt*: 7×7 → 79.95%
      - Valid padding and stride-2 lose information
      - BatchNorm: +0.8 pt, smoother training
      - *Combined* (5 blocks, 3×3, same pad., max-pool, BN): \ #hl[94.52% val., 95.36% test], gap halved
    ],
  )
]

#slide[Task 2b — Optimizers, learning rates, schedulers][
  #grid(columns: (1.15fr, 1fr), gutter: 1cm,
    [#image("figures/nb3_optim.pdf", width: 100%)],
    [
      - 3 optimizers × 3 learning rates, 25 epochs
      - *lr 1e-3 best for all*; 1e-2 unstable for Adam/AdamW, 1e-4 too slow for SGD
      - Adam 1e-3: best and fastest (94.15%)
      - Schedulers add *+1.4–1.7 pts* (StepLR, cosine, OneCycle): small steps at the end remove oscillations
      - Recipe Adam + StepLR: #hl[96.22% test]
    ],
  )
]

#slide[Task 2c — Data augmentation][
  #grid(columns: (1fr, 1fr), gutter: 1cm,
    [
      #image("figures/aug_examples.pdf", width: 100%)
      #v(0.3cm)
      - No "up" in satellite images: *vertical flips and 90° rotations keep the label*
      - Color carries the class → weak jitter only
      - MixUp / CutMix written by hand: \ `loss = lam*CE(out, y_a) + (1-lam)*CE(out, y_b)`
    ],
    [
      #image("figures/nb4_aug.pdf", width: 100%)
      #set text(size: 15pt)
      - Gap (on *clean* train images) 3.9 → ≈1 pt
      - Best: flips + crop + MixUp → #hl[97.04% test]
      - Affine creates black corners; CutMix needs longer training
    ],
  )
]

#slide[Task 2 — Comparison table (selection)][
  #let nb2 = R("NB2_Architecture_Variations", "NB2_summaries.json").summaries
  #let nb3 = R("NB3_Optimizers_LR_Schedulers", "NB3_summaries.json").summaries
  #let nb4 = R("NB4_Data_Augmentation", "NB4_summaries.json").summaries
  #let b4 = R("NB4_Data_Augmentation", "NB4_best_recipe.json")
  #let rows = (
    ("NB2", "baseline", nb2.baseline), ("NB2", "2 blocks", nb2.depth_2blocks), ("NB2", "5 blocks", nb2.depth_5blocks),
    ("NB2", "7×7 kernels", nb2.kernel_7x7), ("NB2", "stride-2", nb2.downsample_stride), ("NB2", "BatchNorm", nb2.batchnorm),
    ("NB2", "combined", nb2.combined),
  ).map(((nb, n, s)) => (nb, n, M(s.params), fx(s.latency_ms, d: 3), fx(s.best_val_acc), fx(s.gen_gap)))
  #let rows2 = (
    ("NB3", "SGD lr 1e-2", nb3.at("SGD_lr0.01")), ("NB3", "Adam lr 1e-3", nb3.at("Adam_lr0.001")), ("NB3", "Adam + StepLR", nb3.at("Adam_lr0.001_StepLR")),
    ("NB4", "no augmentation", nb4.none), ("NB4", "flips + crop", nb4.flips_crop), ("NB4", "+ MixUp", nb4.flips_crop_mixup), ("NB4", "+ CutMix", nb4.flips_crop_cutmix),
  ).map(((nb, n, s)) => (nb, n, M(b4.params), fx(b4.latency_ms, d: 3), fx(s.best_val_acc), fx(s.gen_gap)))
  #let mk(rs) = table(columns: 6, align: (left, left, right, right, right, right),
    table.hline(), [*NB*], [*Config.*], [*Params*], [*Lat. ms*], [*Peak val.*], [*Gap*], table.hline(stroke: .5pt),
    ..rs.flatten(), table.hline())
  #v(0.3cm)
  #show table: set text(size: 15pt)
  #grid(columns: 2, gutter: 1cm, mk(rows), mk(rows2))
  #v(0.4cm)
  #set text(size: 15pt)
  Latency: 1 image on a T4 GPU. Gap: train − val. accuracy at the best epoch (NB4: clean train images). Full table (31 runs) in the report.
]

#slide[Task 3 — Transfer learning with ResNet-18][
  #let nb5 = R("NB5_Transfer_Learning", "NB5_summaries.json").summaries
  #grid(columns: (1.1fr, 1fr), gutter: 0.8cm,
    [
      #image("figures/nb5_transfer.pdf", width: 100%)
      #table(columns: 5, align: (left,) + (right,) * 4,
        table.hline(), [*Test acc. (%)*], [*5%*], [*10%*], [*25%*], [*100%*], table.hline(stroke: .5pt),
        ..(("scratch", "Scratch CNN"), ("frozen", "ResNet frozen"), ("partial", "ResNet layer4"), ("full", "ResNet full")).map(((m, n)) => (
          n, ..(5, 10, 25, 100).map(f => fx(nb5.at(m + "_" + str(f) + "pct").test_acc)))).flatten(),
        table.hline())
    ],
    [
      #set text(size: 15.5pt)
      - ImageNet ResNet-18, images resized to 128×128, ImageNet normalization
      - Freeze with `requires_grad = False`, new head `Dropout → Linear(512, 10)`
      - lr 1e-4 for pretrained layers, 1e-3 for the head
      - *Full fine-tuning: #hl[99.04%]*, and 95.95% with *5% of the data* (945 images)
      - Converges in 1 epoch (scratch: 6)
      - Frozen saturates at ≈90%: last ImageNet layers too object-specific → unfreezing `layer4` recovers most of the gain
      - Cost: 9× params, 3× latency
    ],
  )
]

#slide[Zero-cost NAS — NASWOT (Mellor et al., ICML 2021)][
  #grid(columns: (1fr, 1fr), gutter: 1cm,
    [
      - Judge an architecture *at initialization*, on *one mini-batch*, in ≈0.1 s — no training
      - Binary code $c_i$ of each image: which ReLUs are active
      - Same code = same linear region → the network cannot separate the images
      $ K_H [i,j] = N_A - d_H (c_i, c_j) quad quad s = log |K_H| $
      - High score = images well separated
      - Implemented with *forward hooks* on every `nn.ReLU`
      - Baselines: SynFlow, SNIP, grad-norm, \#params
    ],
    [
      #set text(size: 12pt)
      #show raw: set text(size: 12pt)
      ```python
      def naswot_score(net, inputs):
          B = inputs.size(0)
          K = torch.zeros(B, B, dtype=torch.float64)
          def hook(module, inp, out):
              x = (inp[0].view(B, -1) > 0).double()
              K.add_(x @ x.t() + (1-x) @ (1-x).t())
          for m in net.modules():
              if isinstance(m, nn.ReLU):
                  m.register_forward_hook(hook)
          with torch.no_grad():
              net(inputs)
          return torch.linalg.slogdet(K)[1]
      ```
      #set text(size: 14pt)
      (simplified from NB6.1)
    ],
  )
]

#slide[Step 1 — Reproducing the paper on NAS-Bench-201][
  #let rep = R("NB6_1_NASBench201_Reproduction", "NB6_1_reproduction.json")
  #grid(columns: (1fr, 1.6fr), gutter: 0.8cm,
    [
      - 15,625 networks with *known* trained accuracy
      - Our re-implementation: *same number of parameters* as the official nets for 300/300 archs
      #image("figures/nb61_scatter.pdf", width: 100%)
    ],
    [
      #let t = rep.kendall_tau
      #table(columns: 4, align: (left, center, center, center),
        table.hline(), [*Kendall τ*], [*CIFAR-10*], [*CIFAR-100*], [*IN16-120*], table.hline(stroke: .5pt),
        [ours], fx(t.cifar10.ours, d: 3), fx(t.cifar100.ours, d: 3), fx(t.imagenet16.ours, d: 3),
        [paper], fx(t.cifar10.paper, d: 3), fx(t.cifar100.paper, d: 3), fx(t.imagenet16.paper, d: 3),
        table.hline())
      #v(0.2cm)
      #table(columns: 4, align: (left, center, center, center),
        table.hline(), [*Search, test acc.*], [*CIFAR-10*], [*CIFAR-100*], [*IN16-120*], table.hline(stroke: .5pt),
        ..("NASWOT (N=10)", "NASWOT (N=100)", "Random").map(k => {
          let s = rep.search.at(k)
          ((k + " ours"), ..(1, 3, 5).map(i => fx(s.ours_mean.at(i)) + "±" + fx(s.ours_std.at(i))),
           (k + " paper"), ..(1, 3, 5).map(i => fx(s.paper.at(i).at(0)) + "±" + fx(s.paper.at(i).at(1))))
        }).flatten(),
        table.hline())
      #set text(size: 15pt)
      ✅ Matches Table 2 of the paper within ≈0.1 pt → our implementation is correct.
    ],
  )
]

#slide[Step 2 — Zero-cost NAS on EuroSAT][
  #let nas = R("NB6_2_EuroSAT_ZeroCost_NAS", "NB6_2_nas_results.json")
  #let corr = R("NB6_2_EuroSAT_ZeroCost_NAS", "NB6_2_correlation_study.json").correlations
  #grid(columns: (1fr, 1.25fr), gutter: 0.8cm,
    [
      #set text(size: 15.5pt)
      - Search space = Task 2 knobs: 2–5 blocks, kernel 3/5/7 *per block*, width 16/32/64, BN, pool/stride, skip → *8,640 CNNs*
      - 51 nets trained 5 epochs to check the proxies:
      #table(columns: 6, align: center,
        table.hline(), [], [*NASWOT*], [*SynFlow*], [*SNIP*], [*grad*], [*\#par.*], table.hline(stroke: .5pt),
        [ρ], ..("naswot", "synflow", "snip", "grad_norm", "params").map(p => fx(corr.at(p).at(0))), table.hline())
      - Search: 1000 nets scored in #fx(nas.scoring_time_s, d: 0) s → train top-3
      - NASWOT top-3: 90.8% mean (5 ep.) vs random 83.3%, hand-designed 87.7%
    ],
    [
      #image("figures/nb62_scatter.pdf", width: 52%)
      #table(columns: 5, align: (left,) + (right,) * 4,
        table.hline(), [*Full recipe*], [*Test acc.*], [*Params*], [*Lat.*], [*Search GPU*], table.hline(stroke: .5pt),
        [Hand-designed], fx(nas.final.hand_designed.test_acc), M(nas.final.hand_designed.params), fx(nas.final.hand_designed.latency_ms) + " ms", fx(nas.manual_time_s / 60, d: 0) + " min",
        [*NAS winner*], [*#fx(nas.final.nas_winner.test_acc)*], M(nas.final.nas_winner.params), fx(nas.final.nas_winner.latency_ms) + " ms", [*#fx(nas.nas_time_s / 60, d: 0) min*],
        table.hline())
      #set text(size: 14pt)
      Winner: 5 blocks, kernels 5-3-3-3-3, width 64, BN, max-pool, *residual* → better than our design, *12× less GPU time*
    ],
  )
]

#slide[Final comparison (NB7: all 50 checkpoints)][
  #let m = R("NB7_Final_Evaluation", "NB7_master_results.json").models
  #grid(columns: (1fr, 1fr), gutter: 0.8cm,
    [
      #image("figures/nb7_pareto.pdf", width: 100%)
      #table(columns: 5, align: (left,) + (right,) * 4,
        table.hline(), [*Model*], [*Test acc.*], [*F1*], [*Params*], [*Lat.*], table.hline(stroke: .5pt),
        ..(("Baseline", "NB1_baseline_sgd_lr0.01_bs64_30ep"), ("Hand-designed", "NB4_flips_crop_mixup"), ("NAS winner", "NB6_2_nas_winner"), ("ResNet-18 FT", "NB5_full_100pct")).map(((n, k)) => (
          n, fx(m.at(k).test_acc), fx(m.at(k).test_f1_macro), M(m.at(k).params), fx(m.at(k).latency_ms) + " ms")).flatten(),
        table.hline())
    ],
    [
      #image("figures/nb7_confusion.pdf", width: 100%)
      #set text(size: 15pt)
      - Remaining errors: agricultural classes (PermanentCrop / HerbaceousVeg. / AnnualCrop / Pasture)
      - ResNet: 39 errors vs 120; different mistakes from the scratch CNNs
      - 14 images wrong for all models: mixed land uses
    ],
  )
]

#slide[Conclusions][
  #grid(columns: (1fr, 1fr), gutter: 1cm,
    [
      *Findings*
      - Hand-tuning: #hl[90.15% → 97.04%] — depth & small kernels, Adam + decaying lr, orientation-invariant augmentation
      - Transfer learning: #hl[99.04%], and the best by far with little data (95.95% with 5%) — at 9× the size
      - Zero-cost NAS: *reproduced* on NAS-Bench-201, then found a CNN #hl[better than ours in 17 GPU-min] vs 203
    ],
    [
      *Limitations*
      - Single seed per configuration; repeated runs vary by ≈0.3–1 pt → only large effects are conclusive
      - EuroSAT NAS ground truth = 5-epoch training
      - ImageNet16 scored with substitute images

      #v(0.6cm)
      *Live demo* (NB7): load any checkpoint, classify an image, modify lr / activation / loss / augmentation and retrain in seconds
    ],
  )
]

#page(margin: 2cm)[
  #v(4cm)
  #align(center)[
    #text(size: 34pt, weight: "bold", fill: accent)[Thank you — questions?]
    #v(0.6cm)
    #text(size: 17pt)[Notebooks NB0–NB7 · 50 checkpoints · report & figures generated from the saved results]
  ]
]
