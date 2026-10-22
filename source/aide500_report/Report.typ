// AIDE500 — Technical report (IEEE conference format)
// Compile from this folder:  typst compile --root ../.. --font-path fonts Report.typ
#import "@preview/charged-ieee:0.1.4": ieee

// university logo in the top-left corner of the first page
#set page(background: context if here().page() == 1 { place(left + top, dx: 1.6cm, dy: 0.35cm, image("figures/logo.png", height: 1.35cm)) })

#show: ieee.with(
  title: [From Hand-Tuning to Architecture Search: CNN Design, Transfer Learning and Zero-Cost NAS for Satellite Land-Use Classification],
  abstract: [
    We study how far a convolutional network trained from scratch can go on EuroSAT, a 10-class satellite land-use dataset, and compare three ways of obtaining a good model. First, a baseline CNN is improved *by hand*, one factor at a time: architecture (depth, kernel size, padding, downsampling, BatchNorm), optimizer, learning rate and scheduler, and data augmentation including MixUp and CutMix; test accuracy rises from 90.15% to 97.04%. Second, an ImageNet-pretrained ResNet-18 is transferred with frozen, partially and fully fine-tuned backbones on 5% to 100% of the training data; full fine-tuning reaches 99.04% and still 95.95% with only 945 training images. Third, we implement the training-free NAS score of Mellor et al. (NASWOT) and first *reproduce* the paper on NAS-Bench-201: our Kendall correlations (0.60/0.64/0.60) and search results (e.g. 92.83±0.94% vs. 92.81±0.99% on CIFAR-10 for N=100) match the published numbers. Applied to a EuroSAT search space of 8,640 CNNs, zero-cost NAS finds an architecture that beats our hand-designed network (97.43% vs. 96.72% under the same recipe) with 12× less GPU time.
  ],
  authors: (
    (name: "Emilio Yared", department: [Group 7], organization: [Master 2 Artificial Intelligence and Data Engineering], location: [AIDE500 — Programming for AI]),
    (name: "Joe Missisian", department: [Group 7], organization: [Master 2 Artificial Intelligence and Data Engineering], location: [AIDE500 — Programming for AI]),
  ),
  index-terms: ("Convolutional neural networks", "transfer learning", "data augmentation", "neural architecture search", "remote sensing"),
  bibliography: bibliography("refs.bib"),
)

// ---------- helpers: read the result files of the notebooks ----------
#let R(nb, file) = json("../../results/" + nb + "/" + file)
#let fx(x, d: 2) = {
  let s = str(calc.round(x, digits: d))
  if d == 0 { return s }
  if not s.contains(".") { s += "." }
  s + "0" * (d - s.split(".").at(1).len())
}
#let M(p) = fx(p / 1e6, d: 2) + "M"
#let nb2 = R("NB2_Architecture_Variations", "NB2_summaries.json")
#let nb3 = R("NB3_Optimizers_LR_Schedulers", "NB3_summaries.json")
#let nb4 = R("NB4_Data_Augmentation", "NB4_summaries.json")
#let best4 = R("NB4_Data_Augmentation", "NB4_best_recipe.json")
#let nb5 = R("NB5_Transfer_Learning", "NB5_summaries.json").summaries
#let rep = R("NB6_1_NASBench201_Reproduction", "NB6_1_reproduction.json")
#let nas = R("NB6_2_EuroSAT_ZeroCost_NAS", "NB6_2_nas_results.json")
#let corr = R("NB6_2_EuroSAT_ZeroCost_NAS", "NB6_2_correlation_study.json").correlations
#set table(stroke: none, inset: (x: 3pt, y: 1.6pt))
#show table: set text(size: 7pt)

= Introduction
Satellite images are a natural testbed for small convolutional networks: the classes (forest, river, highway, residential area...) are defined by texture and color rather than by object shape, the images are tiny (64×64 for EuroSAT @helber2019eurosat), and the dataset is large enough (27,000 images) to train a model from scratch. This project follows the three tasks of the course assignment — a baseline CNN (Task 1), a systematic study of architecture, optimization and augmentation (Task 2), and transfer learning (Task 3) — and adds a fourth question: *can the manual design of Task 2 be automated cheaply?* For this we implement zero-cost neural architecture search (NAS) @mellor2021naswot, verify our implementation by reproducing the published results on NAS-Bench-201 @dong2020nasbench201, and then apply it to EuroSAT.

All experiments were run as Jupyter notebooks on a Kaggle T4 GPU (NB0–NB7); every trained configuration is saved as a checkpoint. Every choice (best configuration, best epoch) is made on a validation set; the test set is used only to report final numbers.

= Data and protocol
*EuroSAT RGB* @helber2019eurosat contains 27,000 Sentinel-2 tiles of 64×64 pixels in 10 classes (2,000–3,000 per class). We use a fixed *stratified* 70/15/15 split (18,900 / 4,050 / 4,050 images) saved once in `splits.json`, and normalize with the per-channel mean and standard deviation of the *training* split only, to avoid leaking test statistics.

#figure(placement: top, scope: "parent", image("figures/classes.pdf"),
  caption: [Two EuroSAT examples per class. Several classes differ mostly by texture and color (AnnualCrop / PermanentCrop / HerbaceousVegetation / Pasture), and Highway and River are both thin linear structures.]) <fig:classes>

@fig:classes shows the ten classes. The dataset is balanced enough for accuracy to be meaningful, but some classes are visually close, which is where most errors occur.

*Metrics.* For every epoch we log the training and validation loss, the validation accuracy and the per-class validation accuracy. We report the peak validation accuracy, the *generalization gap* (train − validation accuracy at the best epoch), the number of parameters, the inference latency for one image (batch of 1, GPU synchronized before and after timing), the test accuracy and the macro-F1. Unless stated otherwise, every configuration is trained once with seed 42; repeating a run with the same configuration showed a run-to-run variation of about ±0.3–1.5 points, which we keep in mind when comparing close results.

= Task 1 — Baseline CNN
The baseline (NB1) is a LeNet-style network written like the course labs: three blocks `Conv3×3(pad 1) → ReLU → MaxPool2×2` with 32, 64 and 128 channels ($64 → 32 → 16 → 8$ pixels), a flatten (`x.view(-1, 128*8*8)`) and two fully connected layers (8192 → 256 → 10), 2.19M parameters. It is trained for 30 epochs with SGD (momentum 0.9, lr 0.01, batch 64) and cross-entropy.

#figure(image("figures/nb1_curves.pdf"), caption: [NB1 baseline learning curves: the validation loss is minimal around epoch 6 and then rises while the training accuracy goes to 100%: the network overfits.]) <fig:nb1>

The baseline reaches 89.51% peak validation accuracy and *90.15% test accuracy*. @fig:nb1 shows a textbook overfitting pattern: after epoch 6 the training loss keeps decreasing while the validation loss increases, and the final gap is 10.5 points. The confusion matrix shows that errors are concentrated on visually similar pairs: Highway→River (8.8% of the highways: both are thin linear structures), PermanentCrop→HerbaceousVegetation (8.3%) and Pasture/AnnualCrop. Overfitting and these confusions motivate the three axes of Task 2.

= Task 2 — Systematic study
== Architecture (NB2)
Starting from the baseline, we change *one factor at a time* with a configurable `ConfigNet` (same training as NB1): depth (2–5 conv blocks, channels doubling from 32 up to 256), number of FC layers (1–3), kernel size (3/5/7, padding $k\/2$), valid instead of same padding, stride-2 convolutions instead of max-pooling, and BatchNorm @ioffe2015bn. Finally, the best value of each group is combined. Results are in @fig:nb2 and @tab:task2.

#figure(image("figures/nb2_arch.pdf"), caption: [NB2: peak validation accuracy (bars) and generalization gap (red dots) of each architecture variation.]) <fig:nb2>

*Depth* is the most important factor: each extra block doubles the receptive field (22 → 46 → 94 pixels for 3/4/5 blocks, i.e. the whole tile for 5 blocks) and divides the flattened features by 4, so *deeper networks are also smaller*: 5 blocks give +1.9 points with 1.24M parameters instead of 2.19M, and a smaller gap. With 2 blocks, the first FC layer alone has 4.2M weights and the model overfits the most. *Large kernels hurt* (7×7: 79.95%): with the same depth they add many parameters but no useful context, and training is slower. *Valid padding* loses the borders at every layer, and *stride-2 convolutions* (84.37%) discard 3/4 of the positions before the non-linearity, whereas max-pooling keeps the strongest response. *BatchNorm* gives +0.8 points and smoother training. The combination (5 blocks, 3×3, same padding, max-pooling, BatchNorm, 2 FC) reaches 94.52% validation and *95.36% test* accuracy, with a gap halved compared to the baseline (4.9 vs. 8.9 points in the same run).

== Optimizers, learning rates and schedulers (NB3)
With the NB2 architecture fixed, we compare SGD with momentum (weight decay 5e-4), Adam @kingma2015adam and AdamW @loshchilov2019adamw (weight decay 0.01) at three initial learning rates (25 epochs, @fig:nb3). For all three optimizers *1e-3 is the best learning rate*. At 1e-2 the adaptive optimizers are unstable (Adam ends 1.5 points below its peak, AdamW 3 points), and at 1e-4 SGD is far too slow (23 epochs to reach 90% instead of 6–10). Adam with lr 1e-3 is best (94.15%) and converges fastest. With this pair, a scheduler adds +1.4–1.7 points: StepLR (÷10 every 10 epochs), cosine annealing @loshchilov2017sgdr and OneCycle @smith2019onecycle reach 95.85/95.85/95.53%. Decreasing the learning rate at the end removes the epoch-to-epoch oscillations of the validation accuracy (@fig:nb3, right). The selected recipe (Adam 1e-3 + StepLR) gives *96.22% test accuracy*.

#figure(image("figures/nb3_optim.pdf"), caption: [NB3. Left: peak validation accuracy (%) for each optimizer and initial learning rate. Right: validation accuracy of Adam (lr 1e-3) with each scheduler.]) <fig:nb3>

== Data augmentation (NB4)
Satellite tiles have no canonical orientation, so unlike CIFAR-10 *vertical flips and 90° rotations preserve the label* (@fig:augex). We add augmentations cumulatively (@fig:nb4): flips + rotations by multiples of 90°, `RandomCrop(64, padding=4, reflect)`, `RandomAffine(±15°, scale 0.9–1.1)` and a weak `ColorJitter` (hue ±0.02, because color carries the class: vegetation is green, water blue). MixUp @zhang2018mixup and CutMix @yun2019cutmix are implemented by hand in the training loop, with the mixed loss $lambda "CE"(hat(y), y_a) + (1-lambda) "CE"(hat(y), y_b)$. Because the training accuracy measured on augmented images underestimates overfitting, the gap is computed on a fixed subset of 4,050 *un-augmented* training images.

#figure(image("figures/aug_examples.pdf"), caption: [Label-preserving transformations of a River tile. Flips and 90° rotations are exact; a 15° rotation creates black corners.]) <fig:augex>

#figure(image("figures/nb4_aug.pdf"), caption: [NB4 augmentation ablation (cumulative from left to right; MixUp/CutMix are added to flips+crop). Bars: peak validation accuracy; red: gap measured on clean training images.]) <fig:nb4>

Flips and rotations alone halve the gap (3.9 → 1.9 points) and the gap keeps decreasing down to ≈1 point. Accuracy, however, peaks with flips+crop (96.44%): the ±15° affine rotation creates black corners never seen at test time, and color jitter slightly destroys useful information. MixUp on top of flips+crop gives the best model (96.52% validation, *97.04% test*). CutMix had the smallest gap but its validation accuracy was still increasing at epoch 25: such strong regularization needs longer training.

== Task 2 comparison
@tab:task2 summarizes all Task 2 configurations. Latency is measured on the T4 GPU for one image; since all NB3/NB4 runs share the same network, they have the same size and latency.

#figure(
  placement: top, scope: "parent",
  caption: [Task 2 comparison table: every configuration of NB2 (architecture), the best NB3 runs (optimization) and the NB4 runs (augmentation). Peak val. = best validation accuracy (%); gap = train − validation accuracy at the best epoch (NB4: clean train accuracy).],
  {
    let rows = ()
    for (k, s) in nb2.summaries { rows.push(("NB2", k.replace("_", " "), M(s.params), fx(s.latency_ms, d: 3), fx(s.best_val_acc), fx(s.gen_gap))) }
    let lat = best4.latency_ms
    for k in ("SGD_lr0.01", "Adam_lr0.001", "AdamW_lr0.001", "Adam_lr0.001_StepLR", "Adam_lr0.001_Cosine", "Adam_lr0.001_OneCycle") {
      let s = nb3.summaries.at(k)
      rows.push(("NB3", k.replace("_", " "), M(best4.params), fx(lat, d: 3), fx(s.best_val_acc), fx(s.gen_gap)))
    }
    for (k, s) in nb4.summaries { rows.push(("NB4", k.replace("_", "+"), M(best4.params), fx(lat, d: 3), fx(s.best_val_acc), fx(s.gen_gap))) }
    let half = calc.ceil(rows.len() / 2)
    let head = ([*NB*], [*Configuration*], [*Params*], [*Lat. (ms)*], [*Peak val.*], [*Gap*])
    let mk(rs) = table(columns: 6, align: (left, left, right, right, right, right),
      table.hline(), ..head, table.hline(stroke: .5pt), ..rs.flatten(), table.hline())
    grid(columns: 2, column-gutter: 8pt, mk(rows.slice(0, half)), mk(rows.slice(half)))
  },
) <tab:task2>

= Task 3 — Transfer learning (NB5)
We fine-tune an ImageNet-pretrained ResNet-18 @he2016resnet (11.2M parameters), following the structure of the course script: the parameters are frozen with `requires_grad = False` and the last layer is replaced by `Dropout(0.5) → Linear(512, 10)`. Because ResNet-18 divides the resolution by 32, the tiles are upsampled to 128×128 (4×4 final maps) and normalized with the ImageNet statistics. We compare (i) a *frozen* backbone (5,130 trainable parameters: a linear classifier on ImageNet features), (ii) *partial* fine-tuning of `layer4` and (iii) *full* fine-tuning, with a learning rate of 1e-4 for pretrained layers and 1e-3 for the new head, to avoid destroying the pretrained features. The reference is our best from-scratch CNN. To measure *data efficiency* every method is trained on nested stratified subsets of 5/10/25/100% of the training set, with more epochs for smaller subsets (60/50/30/15) and the same augmentation (flips+crop) and cosine schedule for all.

#figure(image("figures/nb5_transfer.pdf"), caption: [NB5. Left: test accuracy vs. amount of training data. Right: validation accuracy per epoch with 100% of the data.]) <fig:nb5>

#figure(
  caption: [NB5 test accuracy (%) for each fraction of the training data, and epochs to reach 90% validation accuracy with 100% of the data.],
  table(columns: 7, align: (left,) + (right,) * 6,
    table.hline(), [*Method*], [*Train. params*], [*5%*], [*10%*], [*25%*], [*100%*], [*Ep.→90%*], table.hline(stroke: .5pt),
    ..(("scratch", "Scratch CNN", "1.24M"), ("frozen", "ResNet frozen", "5.1k"), ("partial", "ResNet layer4", "8.40M"), ("full", "ResNet full", "11.18M")).map(((m, name, tp)) => (
      name, tp, ..(5, 10, 25, 100).map(f => fx(nb5.at(m + "_" + str(f) + "pct").test_acc)),
      { let e = nb5.at(m + "_100pct").epochs_to_90; if e == none { "never" } else { str(e) } },
    )).flatten(),
    table.hline()),
) <tab:nb5>

Full fine-tuning is the best strategy at every data size (@tab:nb5): *99.04% test accuracy (macro-F1 98.99)* with all the data, and 95.95% with only 5% (945 images) — about the accuracy of our from-scratch CNN trained on 20 times more data. Fine-tuned models also converge much faster: they exceed 90% validation accuracy after the first epoch, against 6 epochs from scratch (@fig:nb5, right). The frozen backbone, in contrast, saturates around 90%: the last ImageNet layers encode object parts (eyes, wheels) that a linear classifier cannot map to subtle land-use textures, and it is overtaken by the from-scratch CNN as soon as 10% of the data is available. Unfreezing only `layer4` recovers most of the gain, which confirms that the *last* layers are the dataset-specific ones. The price of transfer learning is size and speed: ResNet-18 has 9× more parameters and is 3.4× slower than our CNN (2.5 vs. 0.74 ms per image). A side remark: the training accuracies of NB5 are measured on augmented images with dropout active, which makes the frozen model's apparent gap negative; NB4's clean-image measurement should be preferred.

= Zero-cost neural architecture search
== Method
NASWOT @mellor2021naswot scores an *untrained* network on one mini-batch of $B$ images. Each image $i$ gets a binary code $c_i$ indicating which of the $N_A$ ReLUs are active; images with the same code lie in the same linear region of the network and cannot be separated by it. With the kernel $K_H [i,j] = N_A - d_H (c_i, c_j)$ ($d_H$: Hamming distance), the score is $s = log |K_H|$: a high score means the network already separates the inputs well at initialization. We implement it with forward hooks on every `nn.ReLU`, accumulating $x x^T + (1-x)(1-x)^T$ in double precision. For comparison we also implement SynFlow @tanaka2020synflow (data-free), grad-norm and SNIP @lee2019snip, and the number of parameters as a baseline.

== Reproduction on NAS-Bench-201 (NB6.0–NB6.1)
NAS-Bench-201 @dong2020nasbench201 contains 15,625 cell-based networks whose accuracies after 200 epochs on CIFAR-10, CIFAR-100 and ImageNet16-120 are published. We re-implemented its networks from the paper's description; for 300 random architectures our parameter counts match the official ones exactly. Following the paper, we score 1000 random networks on a mini-batch of 128 images of each dataset and compute Kendall's $tau$ with the validation accuracy (ImageNet16 is not available on Kaggle, so for this dataset we score with CIFAR-100 images downsampled to 16×16). For the search, the paper samples $N$ networks, keeps the one with the highest score, and averages over 500 runs; we score all 15,625 networks once and simulate the 500 runs from these scores.

#figure(
  placement: top, scope: "parent",
  caption: [Reproduction of NASWOT on NAS-Bench-201. Top: Kendall $tau$ between the score and the validation accuracy (1000 networks). Bottom: test accuracy (%) of the network selected by the search (mean ± std over 500 runs), ours vs. Table 2 of @mellor2021naswot. Search time is for scoring $N$ networks on a T4 GPU.],
  {
    let t = rep.kendall_tau
    table(columns: 7, align: (left,) + (center,) * 6,
      table.hline(),
      [*Kendall $tau$*], table.cell(colspan: 2)[*CIFAR-10*], table.cell(colspan: 2)[*CIFAR-100*], table.cell(colspan: 2)[*ImageNet16-120*],
      table.hline(stroke: .5pt),
      [], [ours], [paper], [ours], [paper], [ours], [paper],
      [NASWOT score], fx(t.cifar10.ours, d: 3), fx(t.cifar10.paper, d: 3), fx(t.cifar100.ours, d: 3), fx(t.cifar100.paper, d: 3), fx(t.imagenet16.ours, d: 3), fx(t.imagenet16.paper, d: 3),
      table.hline(stroke: .5pt),
      [*Search (test acc.)*], [ours], [paper], [ours], [paper], [ours], [paper],
      ..("NASWOT (N=10)", "NASWOT (N=100)", "NASWOT (N=1000)", "Random", "Optimal (N=100)").map(k => {
        let s = rep.search.at(k)
        (k, ..(1, 3, 5).map(i => (fx(s.ours_mean.at(i)) + "±" + fx(s.ours_std.at(i)), fx(s.paper.at(i).at(0)) + "±" + fx(s.paper.at(i).at(1)))).flatten())
      }).flatten(),
      table.hline())
  },
) <tab:nb201>

#figure(grid(columns: 2, column-gutter: 4pt, image("figures/nb61_scatter.pdf"), image("figures/nb62_scatter.pdf")),
  caption: [NASWOT score at initialization vs. trained accuracy. Left: all NAS-Bench-201 networks. Right: our EuroSAT study (5-epoch training).]) <fig:nas>

@tab:nb201 shows that the reproduction is successful. Our correlations are slightly *higher* than the published ones (0.60/0.64/0.60 vs. 0.57/0.61/0.55; differences of the sampled networks and of the mini-batches), and the search results agree with the paper to within ≈0.1 point for $N = 10$ and $N = 100$ on all three datasets, far inside the standard deviations. Our "Random" and "Optimal" references also match, which validates the benchmark extraction. With the same 1000 networks, the comparison proxies keep the ranking reported by @abdelfattah2021zerocost (Spearman $rho$ on CIFAR-10 test: SynFlow #fx(rep.proxies_cifar10.synflow.ours_spearman) vs. 0.74 published, grad-norm #fx(rep.proxies_cifar10.grad_norm.ours_spearman) vs. 0.58, SNIP #fx(rep.proxies_cifar10.snip.ours_spearman) vs. 0.58), and NASWOT reaches $rho$ = #fx(rep.proxies_cifar10.naswot.ours_spearman). Finally, the ranking of 100 networks computed with five different mini-batches is almost identical (mean $tau$ = #fx(rep.batch_robustness_tau, d: 3)), which justifies scoring each network only once.

== Zero-cost NAS on EuroSAT (NB6.2)
Our search space turns the Task 2 knobs into choices: 2–5 blocks, a kernel size of 3/5/7 *per block*, a width of 16/32/64 channels (doubled at each block), BatchNorm on/off, max-pooling or stride-2 downsampling, and an optional residual connection (1×1 projection) — 8,640 networks, including our hand-designed one. Since no ground truth exists, we trained 50 random networks + the hand-designed one for 5 epochs (Adam 1e-3, no augmentation) and correlated their validation accuracy with the proxies (@fig:nas, right):

#figure(
  caption: [EuroSAT: rank correlation between each proxy and the accuracy after a 5-epoch training (51 networks).],
  table(columns: 6, align: (left,) + (center,) * 5,
    table.hline(), [], [*NASWOT*], [*SynFlow*], [*SNIP*], [*grad-norm*], [*\#params*], table.hline(stroke: .5pt),
    [Spearman $rho$], ..("naswot", "synflow", "snip", "grad_norm", "params").map(p => fx(corr.at(p).at(0))),
    [Kendall $tau$], ..("naswot", "synflow", "snip", "grad_norm", "params").map(p => fx(corr.at(p).at(1))),
    table.hline()),
) <tab:eurocorr>

NASWOT, SNIP and grad-norm are moderately correlated with accuracy ($rho approx 0.43$–$0.56$), while the number of parameters is not ($rho = -0.13$): the proxies measure more than size. SynFlow fails here ($rho = 0.09$); unlike in NAS-Bench-201 (global pooling), our networks end with large flatten+FC layers that dominate its product of absolute weights. Correlations are lower than on NAS-Bench-201, but our ground truth (5 epochs) is itself noisy.

*Search.* We scored 1000 random networks with all proxies in #fx(nas.scoring_time_s, d: 0) s, trained the top-3 by NASWOT and by SynFlow for 5 epochs, and compared with 3 random networks and the hand-designed CNN under the same budget:

#figure(
  caption: [Search on EuroSAT: validation accuracy (%) after 5 epochs of the selected networks.],
  {
    let sr = nas.search_results
    let st(m) = { let a = sr.filter(r => r.method == m).map(r => r.short_val_acc); (fx(a.sum() / a.len()), fx(calc.max(..a))) }
    table(columns: 3, align: (left, center, center),
      table.hline(), [*Selection*], [*Mean*], [*Best*], table.hline(stroke: .5pt),
      [NASWOT top-3], ..st("NASWOT top-3"), [SynFlow top-3], ..st("SynFlow top-3"), [Random (3)], ..st("random"),
      [Hand-designed], ..(fx(R("NB6_2_EuroSAT_ZeroCost_NAS", "NB6_2_correlation_study.json").study.last().short_val_acc),) * 2,
      table.hline())
  },
) <tab:search>

All three NASWOT picks beat both the random networks and our hand-designed CNN. The winner (5 blocks with kernels 5-3-3-3-3, width 64, BatchNorm, max-pooling, residual connections) was then trained with the full NB4 recipe, alongside the hand-designed network in the same run: *97.43% test accuracy vs. 96.72%*, with 1.99M vs. 1.24M parameters and 1.31 vs. 0.76 ms latency. The NAS needed #fx(nas.nas_time_s / 60, d: 0) GPU-minutes (scoring + 6 short trainings) against #fx(nas.manual_time_s / 60, d: 0) minutes for the 31 trainings of NB2–NB4 — about 12 times less. The search rediscovered the main lessons of Task 2 (depth 5, small kernels, max-pooling, BatchNorm) and added the two changes we had not tried: more width and residual connections.

= Implementation and reproducibility
The project is organized as nine notebooks (@tab:notebooks), each self-contained so that it can be executed live: helper functions (`train_one_epoch`, `evaluate`, `measure_latency`) are defined inside each notebook, training loops are written explicitly (`zero_grad`, forward, `backward`, `step`), and every trained configuration is saved with `torch.save(net.state_dict())`. Notebooks are pushed to Kaggle with the command-line API, executed on a T4 GPU, and their outputs (executed notebook, checkpoints, JSON histories) are downloaded; later notebooks read the results of earlier ones (e.g. NB3 starts from the architecture chosen in NB2), which makes the whole study reproducible end-to-end from the fixed split and seed. All figures and tables of this report are generated from these JSON files.

#figure(
  caption: [Notebooks of the project and number of trained configurations (all saved as checkpoints, except the 5-epoch NAS evaluations).],
  table(columns: 3, align: (left, left, right),
    table.hline(), [*NB*], [*Content*], [*Runs*], table.hline(stroke: .5pt),
    [0], [split, normalization statistics], [–],
    [1], [baseline CNN (Task 1)], [1],
    [2], [architecture variations (Task 2a)], [12],
    [3], [optimizers × lr, schedulers (Task 2b)], [12],
    [4], [augmentation, MixUp/CutMix (Task 2c)], [7],
    [5], [transfer learning × data fraction (Task 3)], [16],
    [6.0/6.1], [NAS-Bench-201 extraction + NASWOT reproduction], [–],
    [6.2], [zero-cost NAS on EuroSAT], [60 + 2],
    [7], [evaluation of all checkpoints, live demo], [–],
    table.hline()),
) <tab:notebooks>

= Final comparison and discussion
#figure(image("figures/nb7_pareto.pdf"), caption: [NB7: test accuracy vs. single-image latency of all 50 checkpoints, re-evaluated on the same test set.]) <fig:pareto>

#figure(image("figures/nb7_confusion.pdf"), caption: [Normalized test confusion matrices of the hand-designed CNN (left) and the fine-tuned ResNet-18 (right).]) <fig:cm>

#figure(
  caption: [The three final models on the test set (4,050 images), re-evaluated in NB7. Latency: one image on a T4 GPU.],
  {
    let m = R("NB7_Final_Evaluation", "NB7_master_results.json").models
    let y = R("NB7_Final_Evaluation", "NB7_master_results.json").labels
    table(columns: 6, align: (left,) + (right,) * 5,
      table.hline(), [*Model*], [*Acc.*], [*F1*], [*Params*], [*Lat.*], [*Errors*], table.hline(stroke: .5pt),
      ..(("Baseline (NB1)", "NB1_baseline_sgd_lr0.01_bs64_30ep"), ("Hand-designed (NB4)", "NB4_flips_crop_mixup"), ("NAS winner (NB6.2)", "NB6_2_nas_winner"),
         ("ResNet-18 frozen", "NB5_frozen_100pct"), ("ResNet-18 fine-tuned", "NB5_full_100pct")).map(((n, k)) => {
        let r = m.at(k)
        (n, fx(r.test_acc), fx(r.test_f1_macro), M(r.params), fx(r.latency_ms) + " ms", str(r.preds.zip(y).filter(((p, t)) => p != t).len()))
      }).flatten(),
      table.hline())
  },
) <tab:final>

NB7 reloads all 50 checkpoints and re-evaluates them on the test set (@fig:pareto, @tab:final); every number matches the one obtained in its own notebook. The final models offer three trade-offs: the hand-designed CNN (97.04%, 1.24M parameters, 0.79 ms) is the fastest, the NAS winner removes 13% of its errors for a 1.6× slower network, and the fine-tuned ResNet-18 is by far the most accurate (99.04%, 39 errors instead of 120) but also the largest and slowest. The confusion matrices (@fig:cm) show that, once Highway/River has been largely fixed by depth and augmentation, the remaining errors of the from-scratch models concentrate on the agricultural classes (PermanentCrop→HerbaceousVegetation, Pasture/River→AnnualCrop), whose 64×64 textures are genuinely ambiguous; ImageNet features reduce these confusions by a factor of 2–3. The two from-scratch models share most of their errors (72 in common), whereas ResNet-18 fails on different images (only 15–17 in common with each), which suggests that an ensemble of a scratch CNN and the ResNet could still help. 14 test images are misclassified by all three models; inspecting them in NB7, most are patchworks of fields confused between AnnualCrop, Pasture and PermanentCrop, plus a river running along a road and an industrial area crossed by a large road: tiles mixing several land uses, for which a single label is debatable.

*Limitations.* Each configuration was trained with a single seed, while repeated runs differ by up to ≈1 point, so small differences (e.g. between the top augmentation settings, or StepLR vs. cosine) are not significant; the large effects (depth, kernel size, scheduler, augmentation on the gap, transfer learning, NAS vs. random) are well beyond this noise. Our EuroSAT NAS ground truth uses a short training, and the ImageNet16 reproduction uses substitute images.

= Conclusion
Careful hand-tuning took a simple CNN from 90.15% to 97.04% test accuracy: depth and small kernels gave the largest architectural gains, Adam with a decaying learning rate the best optimization, and orientation-invariant augmentation removed most of the overfitting. Transfer learning from ImageNet remains the most accurate and by far the most data-efficient option (95.95% with 5% of the data), at a 9× size cost. Finally, after reproducing the published results of training-free NAS on NAS-Bench-201, we showed that it transfers to a new problem: in minutes, it found a CNN better than the one we designed by hand in hours.
