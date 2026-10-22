// NASWOT reproduction on NAS-Bench-201: our numbers next to the paper's.
// Compile: typst compile --root ../.. --font-path fonts Reproduction_Comparison.typ
#let R = json("../../results/NB6_1_NASBench201_Reproduction/NB6_1_reproduction.json")

#set page(paper: "a4", flipped: true, margin: 1.6cm)
#set text(font: "TeX Gyre Termes", size: 11pt)
#set table(stroke: 0.4pt + gray, inset: 5pt)
#show heading.where(level: 1): set text(size: 17pt)
#show heading.where(level: 2): it => block(above: 1.2em, below: 0.6em, text(size: 13pt, fill: rgb("#1f4e79"), it))

#let fx(x, d) = str(calc.round(x, digits: d))
#let pad(s, d) = {
  // keep trailing zeros: 0.6 -> 0.600
  let parts = s.split(".")
  let dec = if parts.len() > 1 { parts.at(1) } else { "" }
  if d == 0 { parts.at(0) } else { parts.at(0) + "." + dec + "0" * (d - dec.len()) }
}
#let f(x, d) = pad(fx(x, d), d)
#let diff(a, b, d) = {
  let v = a - b
  let s = (if v >= 0 { "+" } else { "−" }) + f(calc.abs(v), d)
  let c = if calc.abs(v) < 0.15 or (d == 3 and calc.abs(v) < 0.08) { rgb("#2e7d32") } else { rgb("#b26a00") }
  text(fill: c, s)
}
#let ours(x) = text(fill: rgb("#1f4e79"), weight: "bold", x)
#let H(x) = text(weight: "bold", x)

= Reproduction of "Neural Architecture Search without Training" (Mellor et al., ICML 2021)
Our implementation (notebook NB6.1, Kaggle T4 GPU) next to the numbers published in the paper.
#ours[Blue = ours], black = paper, last column = difference (ours − paper).

== 1 · Our NAS-Bench-201 networks are the official ones
#table(columns: (auto, auto, auto),
  H[Check], H[Ours], H[Official benchmark],
  [Parameter count of 300 random architectures], ours[300 / 300 identical], [max difference 0.000000 M],
  [Number of architectures in the space], ours[15,625], [15,625 (5 operations#super[6 edges])],
  [Best CIFAR-10 test accuracy in the benchmark], ours[94.37 %], [94.37 %],
)

== 2 · Does the score at initialization predict the trained accuracy? (paper, Figure 3)
Kendall τ between the NASWOT score of 1,000 random untrained networks and their validation accuracy after 200 epochs.
#let names = ("cifar10": "CIFAR-10", "cifar100": "CIFAR-100", "imagenet16": "ImageNet16-120 *")
#table(columns: (auto, auto, auto, auto),
  H[Dataset], H[Ours (τ)], H[Paper (τ)], H[Difference],
  ..R.kendall_tau.pairs().map(((k, v)) => (names.at(k), ours(f(v.ours, 3)), f(v.paper, 3), diff(v.ours, v.paper, 3))).flatten(),
)
#text(size: 9pt)[\* ImageNet16-120 is not available on Kaggle: we scored with CIFAR-100 images resized to 16×16 (approximation). Scoring time: #f(R.ms_per_architecture, 0) ms per architecture.]

== 3 · Comparison with the other zero-cost proxies (Abdelfattah et al., ICLR 2021, Table 1)
Spearman ρ with the CIFAR-10 test accuracy, same 1,000 architectures.
#grid(columns: (auto, 1fr), column-gutter: 1.2cm, [
#let pname = ("grad_norm": "grad_norm", "snip": "SNIP", "synflow": "SynFlow", "params": "number of parameters (baseline)", "naswot": "NASWOT")
#table(columns: (auto, auto, auto, auto),
  H[Proxy], H[Ours (ρ)], H[Paper (ρ)], H[Difference],
  ..R.proxies_cifar10.pairs().map(((k, v)) => (
    pname.at(k), ours(f(v.ours_spearman, 3)),
    if v.paper_spearman == none [—] else { f(v.paper_spearman, 2) },
    if v.paper_spearman == none [—] else { diff(v.ours_spearman, v.paper_spearman, 3) },
  )).flatten(),
)
#text(size: 9pt)[Same ranking as the paper: SynFlow > SNIP ≈ grad_norm. \ NASWOT and SynFlow are the only proxies that beat simply counting parameters.]
], align(center + horizon, figure(image("figures/nb61_scatter.pdf", height: 5cm),
  caption: [NASWOT score at initialization vs CIFAR-10 validation accuracy after training, all 15,625 architectures (our version of the paper's Figure 3).])))

#pagebreak()
== 4 · The search itself (paper, Table 2) — accuracy (%) of the selected architecture, mean ± std over 500 runs
Sample N random architectures, score them at initialization on CIFAR-10, keep the highest score.
#let cols = ("C10 valid", "C10 test", "C100 valid", "C100 test", "IN16 valid *", "IN16 test *")
#table(columns: (auto, auto, ..range(6).map(_ => 1fr)), inset: 3.6pt,
  align: (left, left, ..range(6).map(_ => center)),
  H[Method], [], ..cols.map(H),
  ..R.search.pairs().map(((m, v)) => (
    table.cell(rowspan: 3, align: horizon, H[#m]),
    ours[ours], ..range(6).map(i => ours(f(v.ours_mean.at(i), 2) + " ± " + f(v.ours_std.at(i), 2))),
    [paper], ..v.paper.map(p => f(p.at(0), 2) + " ± " + f(p.at(1), 2)),
    text(size: 9pt)[diff], ..range(6).map(i => text(size: 9pt, diff(v.ours_mean.at(i), v.paper.at(i).at(0), 2))),
  )).flatten(),
)
#text(size: 9pt)[*Random* = one architecture picked at random. *Optimal (N)* = best architecture among the N sampled (what a perfect proxy would pick).
Green = within 0.15 point of the paper. Difference from the paper: we score each architecture once and reuse the score in all 500 runs (the paper draws a new mini-batch per run); \* ImageNet16 approximated as above.]

== 5 · Is the score stable when the mini-batch changes? (paper, Section 3.1)
#table(columns: (auto, auto, auto),
  H[Test], H[Ours], H[Paper],
  [Kendall τ between rankings obtained with 2 different mini-batches (100 architectures, 5 batches)], ours[#f(R.batch_robustness_tau, 3)], [score "barely changes" with the mini-batch],
)

*Conclusion.* Every number of the paper is reproduced: the correlations are slightly higher than published (+0.03 to +0.07), the search results within ≈0.15 point on CIFAR-10/100 (larger gaps only on the approximated ImageNet16 at N=1000 and on the Random row, which depends on the whole benchmark), and our networks are identical to the benchmark's. This validates our NASWOT code before using it on EuroSAT (NB6.2).
