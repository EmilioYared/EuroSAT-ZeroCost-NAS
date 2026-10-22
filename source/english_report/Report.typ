// English project — professional report (structure of Chapter 3, Dr. Zeinab Abbas)
// Compile from this folder:  typst compile --root ../.. Report.typ
#let G = rgb("#13613F")
#let LG = rgb("#EEF4F0")
#let F(name) = "../aide500_report/figures_slides/" + name
#let E(name) = "figures/" + name
#let D = json("experiments/nas_comparison.json")
#let r2(x) = str(calc.round(x, digits: 2))
#let pm(m, s) = r2(m) + " ± " + r2(s)

#set document(title: "Designing Convolutional Networks for Satellite Image Classification", author: "Emilio Yared")
#set page(paper: "a4", margin: 2.5cm)
#set text(font: "Times New Roman", size: 12pt, lang: "en")
#set par(justify: true, leading: 0.95em, spacing: 1.45em, first-line-indent: 0pt)
#set heading(numbering: "1.1")
#show heading: set text(fill: G)
#show heading.where(level: 1): it => {
  pagebreak(weak: true)
  v(0.6cm)
  block(below: 0.9cm, text(size: 21pt, weight: "bold", it))
}
#show heading.where(level: 2): set text(size: 16pt)
#show heading.where(level: 2): set block(above: 1.4em, below: 0.9em)
#show heading.where(level: 3): set text(size: 14pt)
#set list(indent: 0.6cm, spacing: 0.9em)
#set enum(indent: 0.6cm, spacing: 0.9em)
#set figure(gap: 0.8em, placement: auto)
#set figure.caption(separator: [. ])
#show figure.caption: set text(size: 12pt)
#show figure.caption: it => [*#it.supplement #context it.counter.display(it.numbering)#it.separator*#it.body]
#show figure.where(kind: table): set figure.caption(position: top)
#show figure: set block(above: 1.6em, below: 1.6em)
#show table: set text(size: 12pt)
#show table: set par(justify: false, leading: 0.6em)
#set table(stroke: 0.5pt + rgb("#9AA9A0"), inset: 6pt,
  fill: (x, y) => if y == 0 { G } else if calc.even(y) { LG } else { white })
#show table.cell.where(y: 0): set text(fill: white, weight: "bold")
#show raw.where(block: true): set text(size: 9.5pt)
#show raw.where(block: true): set par(justify: false)
#show raw.where(block: true): block.with(fill: LG, inset: 10pt, radius: 4pt, width: 100%)
#let in-outline = state("in-outline", false)
#show outline: it => { in-outline.update(true); it; in-outline.update(false) }
#let cap(long, short) = context if in-outline.get() { short } else { long }
#show outline: set text(size: 12pt)
#show outline: set par(leading: 0.55em)
#show outline.entry: set block(above: 0.5em)
#show outline.entry.where(level: 1): it => if it.element.func() == heading { strong(it) } else { it }
#show outline.entry.where(level: 1): set block(above: 0.75em)

// ===================================================================== cover page
#set page(numbering: none)
#align(center)[
  #set par(justify: false)
  #grid(columns: 2, column-gutter: 1.2cm, align: horizon,
    image("figures/logo1.png", height: 3.0cm), image("figures/logo2.png", height: 3.0cm))
  #v(0.3cm)
  #text(size: 17pt, weight: "bold")[Lebanese University] \
  #text(size: 14pt)[Faculty of Science]
  #v(1.6cm)
  #text(size: 15pt, fill: G, weight: "bold", tracking: 2pt)[FINAL REPORT]
  #v(0.5cm)
  #line(length: 70%, stroke: 1.2pt + G)
  #v(0.3cm)
  #text(size: 24pt, weight: "bold", hyphenate: false)[Designing Convolutional Networks for Satellite Image Classification]
  #v(0.2cm)
  #text(size: 16pt, style: "italic", hyphenate: false)[Hand-Design, Transfer Learning and Training-Free Neural Architecture Search on EuroSAT]
  #v(0.3cm)
  #line(length: 70%, stroke: 1.2pt + G)
  #v(2.2cm)
  #set text(size: 14pt)
  #grid(columns: (auto, auto), column-gutter: 0.5cm, row-gutter: 0.6cm, align: (right, left),
    [*Prepared by:*], [Emilio Yared],
    [*Program:*], [Professional Master's in Artificial Intelligence \ and Data Engineering (M2)],
    [*Course:*], [Scientific English and Communication Skills],
    [*Supervisor:*], [Dr. Zeinab Abbas],
    [*Date of submission:*], [October 2026],
  )
]

// ===================================================================== front matter
#set page(numbering: "i", number-align: center + bottom)
#counter(page).update(1)

#heading(level: 1, numbering: none, outlined: false)[Acknowledgements]
I would like to express my sincere gratitude to my supervisor, Dr. Zeinab Abbas, for her continuous guidance and constructive feedback on the structure and the language of this report.

I would also like to thank my colleague Joe Missisian, with whom the experimental work of the AIDE500 project "Programming for AI" was carried out, as well as the course instructors for providing the computing resources and laboratory material on which the implementation is based.

Finally, my appreciation goes to the authors of the EuroSAT dataset and of the NAS-Bench-201 benchmark for making their data publicly available, and to the Kaggle platform for providing free access to graphics processing units.

#heading(level: 1, numbering: none, outlined: false)[Abstract]
Satellite image classification supports land-use monitoring, but the design of an accurate convolutional neural network (CNN) for a new dataset still requires a long process of trial and error. This study compared three approaches for building a classifier for the EuroSAT RGB dataset (27,000 images, ten land-cover classes): the manual design of a CNN trained from scratch, transfer learning from an ImageNet-pretrained ResNet-18, and training-free neural architecture search (NAS) based on the NASWOT score. The NASWOT score was first reproduced on the NAS-Bench-201 benchmark and compared with five search strategies (random search, regularised evolution, local search, REINFORCE and assisted evolution), each executed 200 times. Manual design increased the test accuracy of the baseline CNN from 90.15% to 97.04%, whereas the fully fine-tuned ResNet-18 reached 99.04%, and 95.95% with only 5% of the training data. On NAS-Bench-201, NASWOT matched the published results within 0.1 percentage point in a few seconds, while regularised evolution required 100 trained networks to obtain a further gain of 1.2 points. On EuroSAT, the architecture selected by NASWOT reached 97.43% with twelve times less GPU time than manual design. These findings indicate that training-free search is a practical first step for designing compact models, whereas transfer learning remains the most accurate option when model size is not constrained.

#v(0.4cm)
*Keywords:* convolutional neural networks, satellite imagery, EuroSAT, transfer learning, neural architecture search, NASWOT, zero-cost proxies.

#heading(level: 1, numbering: none, outlined: false)[Table of Contents]
#outline(title: none, depth: 2, indent: 1.2em)

#heading(level: 1, numbering: none, outlined: false)[List of Figures]
#outline(title: none, target: figure.where(kind: image))

#heading(level: 1, numbering: none, outlined: false)[List of Tables]
#outline(title: none, target: figure.where(kind: table))

#heading(level: 1, numbering: none, outlined: false)[List of Abbreviations]
#table(columns: (3.2cm, 1fr), stroke: none, fill: none, inset: (x: 4pt, y: 5pt),
  table.header([], []),
  [*AREA*], [Assisted Regularised Evolution],
  [*BN*], [Batch Normalisation],
  [*BOHB*], [Bayesian Optimisation and HyperBand],
  [*CNN*], [Convolutional Neural Network],
  [*DARTS*], [Differentiable Architecture Search],
  [*ENAS*], [Efficient Neural Architecture Search],
  [*F1*], [Harmonic mean of precision and recall],
  [*GPU*], [Graphics Processing Unit],
  [*LS*], [Local Search],
  [*NAS*], [Neural Architecture Search],
  [*NASWOT*], [Neural Architecture Search Without Training],
  [*ReLU*], [Rectified Linear Unit],
  [*REA*], [Regularised Evolution],
  [*RGB*], [Red, Green and Blue channels],
  [*RS*], [Random Search],
  [*RSPS*], [Random Search with Parameter Sharing],
  [*SGD*], [Stochastic Gradient Descent],
  [*SNIP*], [Single-shot Network Pruning],
)

// ===================================================================== main matter
#set page(numbering: "1", number-align: center + bottom)
#counter(page).update(1)

= Introduction

== Context and Problem Statement
Earth observation satellites such as Sentinel-2 acquire images of the entire surface of the planet every few days. These images are used to monitor agriculture, urban expansion, deforestation and water resources. Since the volume of data is far too large for manual inspection, the automatic classification of land use and land cover has become an important application of deep learning @helber2019eurosat.

Convolutional neural networks (CNNs) are currently the standard tool for image classification @lecun1998cnn @krizhevsky2012alexnet. However, the performance of a CNN depends strongly on its architecture, that is, on the number of layers, the size of the kernels, the width of each layer and the connections between them. In practice, this architecture is designed manually: an engineer proposes a network, trains it, observes the results and modifies the design. Each iteration requires a complete training run, which may last from several minutes to several days. Consequently, manual design is slow, expensive and strongly dependent on the experience of the designer.

Two families of methods have been proposed to reduce this effort. The first one, transfer learning, reuses a network that has already been trained on a large dataset such as ImageNet @deng2009imagenet and adapts it to the new task @yosinski2014transferable. The second one, neural architecture search (NAS), automates the design of the architecture itself @elsken2019survey. Early NAS methods were extremely costly: the original algorithm of Zoph and Le @zoph2017nas used 800 GPUs for 28 days. More recently, Mellor et al. @mellor2021naswot proposed NASWOT, a training-free method that scores an architecture at initialisation in less than one second. If such a score is reliable, the cost of architecture design could be reduced from hours to seconds.

== Objectives
The main objective of this project was to compare the three approaches (manual design, transfer learning and training-free NAS) on the same satellite image classification task. More specifically, the objectives were:

+ To build a baseline CNN for the EuroSAT dataset and to improve it systematically by modifying its architecture, its optimiser and its data augmentation strategy.
+ To evaluate transfer learning from an ImageNet-pretrained ResNet-18 with different amounts of training data.
+ To reproduce the NASWOT results of Mellor et al. @mellor2021naswot on the NAS-Bench-201 benchmark @dong2020nasbench201, and to compare NASWOT with five other NAS strategies.
+ To apply NASWOT to a search space of CNNs designed for EuroSAT and to compare the resulting network with the manually designed one.

== Importance of the Project
This project is important for two reasons. From a practical point of view, organisations that process satellite images often need models that run on limited hardware, for example on board a satellite or on a field device. Knowing the trade-off between accuracy, model size and design cost helps engineers to select the appropriate approach. From a methodological point of view, NAS papers frequently report results that are difficult to reproduce. An independent reproduction on a public benchmark therefore provides evidence on whether training-free search can be trusted in practice.

== Structure of the Report
The remainder of this report is organised as follows. Chapter 2 presents the necessary background on CNNs, transfer learning and NAS. Chapter 3 describes the dataset, the three approaches and the evaluation protocol. Chapter 4 reports and analyses the results. Chapter 5 discusses their implications and provides recommendations. Finally, Chapter 6 concludes the report. Additional details are provided in the appendices.

= Background

== Convolutional Neural Networks
A CNN is a neural network that processes images through a sequence of convolutional layers @lecun1998cnn. Each convolutional layer applies a set of small filters (kernels), typically of size 3×3 or 5×5, to its input. Each filter detects a local pattern such as an edge, a colour transition or a texture. The output of the convolution is passed through a non-linear activation function, usually the rectified linear unit (ReLU), defined as $"ReLU"(x) = max(0, x)$.

Pooling layers reduce the spatial resolution of the feature maps, so that the deeper layers observe a larger region of the image, and fully connected layers at the end of the network produce a score for each class.

Several components have been introduced to make deep CNNs easier to train. Batch normalisation (BN) normalises the activations of each layer and allows higher learning rates @ioffe2015bn. Residual (skip) connections, introduced in ResNet @he2016resnet, add the input of a block to its output; this allows the gradient to flow through very deep networks. Finally, the use of several small kernels instead of a single large kernel was popularised by the VGG networks @simonyan2015vgg, since two 3×3 convolutions cover the same receptive field as one 5×5 convolution with fewer parameters.

== Optimisation and Regularisation
The weights of a CNN are learnt by minimising a loss function, generally the cross-entropy, with a gradient-based optimiser. Stochastic gradient descent (SGD) with momentum updates the weights in the direction opposite to the gradient. Adam @kingma2015adam adapts the learning rate of each parameter individually, and AdamW @loshchilov2019adamw decouples the weight decay from this adaptation. The learning rate itself can be decreased during training by a scheduler, for example a step decay, a cosine annealing @loshchilov2017sgdr or a one-cycle policy @smith2019onecycle.

When the training set is small compared to the capacity of the network, the model may memorise the training images instead of learning general features; this phenomenon is called overfitting. Data augmentation reduces overfitting by applying random transformations (flips, crops, rotations or colour changes) to the training images. More advanced methods such as mixup @zhang2018mixup and CutMix @yun2019cutmix combine two images and their labels into a single training example.

== Transfer Learning
Transfer learning consists in reusing a network trained on a large source dataset for a different target task. Yosinski et al. @yosinski2014transferable demonstrated that the first layers of a CNN learn generic features (edges, textures), whereas the last layers learn features that are specific to the source task. Two strategies are commonly used:

- *Feature extraction:* the pretrained layers are frozen and only a new classification layer is trained.
- *Fine-tuning:* some or all of the pretrained layers are trained further on the target data, usually with a smaller learning rate.

This is particularly effective when the target dataset is small.

== Neural Architecture Search
NAS automates the design of neural network architectures. According to the survey of Elsken et al. @elsken2019survey, every NAS method can be described by three components:

- *Search space:* the set of architectures that can be represented, for example all combinations of a fixed number of layers and operations.
- *Search strategy:* the algorithm that explores the search space, such as random sampling, evolution or reinforcement learning.
- *Performance estimation strategy:* the method used to estimate the quality of a candidate architecture. The most reliable but most expensive strategy is to train the candidate completely.

=== Training-Based Search Strategies
The first NAS algorithms trained every candidate architecture. Zoph and Le @zoph2017nas used a recurrent controller network trained with the REINFORCE algorithm @williams1992reinforce: the controller proposes an architecture, the architecture is trained, and its accuracy is used as a reward to update the controller. Real et al. @real2019rea proposed regularised evolution (REA), in which a population of architectures is improved by mutation, and the oldest individuals are removed from the population. Bayesian optimisation methods such as BOHB @falkner2018bohb build a model of the accuracy as a function of the architecture. White et al. @white2021localsearch showed that a simple local search, which repeatedly moves to the best neighbouring architecture, is highly competitive on NAS benchmarks.

=== Weight-Sharing Methods
To reduce the cost of training each candidate, weight-sharing methods train a single "super-network" that contains all the candidate architectures. ENAS @pham2018enas, DARTS @liu2019darts, GDAS @dong2019gdas, SETN @dong2019setn and random search with parameter sharing (RSPS) @li2019rsps belong to this family. These methods are faster but unstable @dong2020nasbench201.

=== Training-Free Search and Zero-Cost Proxies
Training-free methods estimate the quality of an architecture without any training, by computing a score at initialisation. Abdelfattah et al. @abdelfattah2021zerocost evaluated several of these "zero-cost proxies", including SNIP @lee2019snip, SynFlow @tanaka2020synflow and the gradient norm. Mellor et al. @mellor2021naswot proposed the NASWOT score, which is based on the activation patterns of the ReLU units and is described in detail in Section 3.5.

== NAS Benchmarks
Comparing NAS methods is difficult, because each method is usually evaluated on a different search space with a different training procedure. NAS-Bench-201 @dong2020nasbench201 addresses this problem. It defines a search space of 15,625 cell-based architectures and provides the accuracy of every architecture after a complete training on CIFAR-10, CIFAR-100 and ImageNet16-120. As a result, a search strategy can be evaluated by simply looking up the accuracy of the architectures that it selects, without training any network. Each cell is a small directed graph with four nodes and six edges, and each edge applies one of five operations, as illustrated in @fig-cell.

#figure(image(E("en_cell.png"), width: 50%),
  caption: cap([Example of a NAS-Bench-201 cell. Each of the six edges applies one of five operations (none, skip connection, 1×1 convolution, 3×3 convolution or 3×3 average pooling), which gives 5#super[6] = 15,625 architectures.], [Example of a NAS-Bench-201 cell])) <fig-cell>

== Related Work on EuroSAT
Helber et al. @helber2019eurosat introduced the EuroSAT dataset and reported an accuracy of 98.57% on the RGB version with a fine-tuned ResNet-50. To the best of our knowledge, training-free architecture search has not been evaluated on EuroSAT in previous work, which motivates the third part of this project.

= Methodology

== Overview
The project was organised as a pipeline of experiments, as illustrated in @fig-pipeline. All the experiments used the same dataset split and the same test set, so that the three approaches could be compared fairly.

#figure(placement: none, image(E("en_pipeline.png"), width: 70%),
  caption: cap([Overview of the experimental pipeline. The three approaches share the same data split and are evaluated on the same 4,050 test images.], [Overview of the experimental pipeline])) <fig-pipeline>

== Dataset
The EuroSAT RGB dataset @helber2019eurosat was obtained from Kaggle. It contains 27,000 images of 64×64 pixels extracted from Sentinel-2 satellite data, labelled into ten land-use and land-cover classes. @tab-dataset summarises its main characteristics, and @fig-classes shows one example per class.

#figure(table(columns: (1fr, auto), align: (left, left),
  [Characteristic], [Value],
  [Number of images], [27,000],
  [Image size], [64 × 64 pixels, 3 channels (RGB)],
  [Number of classes], [10],
  [Images per class], [2,000 to 3,000],
  [Training / validation / test split], [18,900 / 4,050 / 4,050 (70% / 15% / 15%)],
  [Split strategy], [Stratified by class, fixed random seed (42)],
  [Source], [Sentinel-2 satellite, 13 European countries],
), caption: cap([Summary of the EuroSAT RGB dataset.], [Summary of the EuroSAT RGB dataset])) <tab-dataset>

#figure(image(F("classes.png"), width: 80%),
  caption: cap([One example image from each of the ten EuroSAT classes.], [Example images of the ten EuroSAT classes])) <fig-classes>

The dataset is approximately balanced (2,000 to 3,000 images per class).

== Data Preprocessing
The split into training, validation and test sets was computed once in the first notebook (NB0) and saved in a file that was reused by all the other notebooks. The mean and standard deviation of each colour channel were computed on the training set only and were used to normalise all images. All the design decisions were based on the validation set, and the test set was used only once per model.

== Approach 1: Manual Design of a CNN
=== Baseline Network
The baseline network consisted of three convolutional blocks followed by two fully connected layers. Each block contained a 3×3 convolution with padding, a ReLU activation and a 2×2 max-pooling layer. The number of channels was doubled at each block (32, 64 and 128), and the classifier contained a hidden layer of 256 units. The network had 2.19 million parameters. It was trained for 30 epochs with SGD (learning rate 0.01, momentum 0.9) and a batch size of 64.

=== Systematic Study
Starting from the baseline, one factor was modified at a time, while all the others were kept constant. Three groups of experiments were conducted:

- *Architecture:* number of convolutional blocks (2 to 5), kernel size (3×3, 5×5, 7×7), padding, down-sampling by pooling or by strided convolution, number of fully connected layers, and batch normalisation.
- *Optimisation:* three optimisers (SGD, Adam, AdamW), three learning rates (10#super[−2], 10#super[−3], 10#super[−4]) and three learning-rate schedulers (step decay, cosine annealing and one-cycle).
- *Data augmentation:* horizontal and vertical flips, random crops, affine transformations, colour jitter, mixup and CutMix.

The best option of each group was retained for the following group, and the final model combined the best architecture, the best optimiser and the best augmentation strategy. This final model is referred to as the "hand-designed CNN" in the rest of the report.

== Approach 2: Transfer Learning
A ResNet-18 @he2016resnet pretrained on ImageNet was used as the source network. The images were resized to 128×128 pixels and normalised with the ImageNet statistics. The final layer was replaced by a dropout layer followed by a linear layer with ten outputs. Three strategies were compared with a CNN trained from scratch:

- *Frozen:* all pretrained layers were frozen and only the new classifier was trained.
- *Partial fine-tuning:* the last residual stage (layer4) and the classifier were trained.
- *Full fine-tuning:* all layers were trained, with a learning rate of 10#super[−4] for the pretrained layers and 10#super[−3] for the classifier.

In order to study the effect of the amount of data, each strategy was trained with 5%, 10%, 25% and 100% of the training set.

== Approach 3: Training-Free Architecture Search
=== The NASWOT Score
The NASWOT score @mellor2021naswot is computed on an untrained network and a single mini-batch of $B$ images. For each image $i$, the state of every ReLU unit (active or inactive) is recorded, which gives a binary code $c_i$. Two images with the same code fall into the same linear region of the network, which means that the network cannot easily separate them. The kernel matrix $K_H$ is defined as:

$ K_H [i, j] = N_A - d_H (c_i, c_j) $

where $N_A$ is the number of ReLU units and $d_H$ is the Hamming distance between the two codes. The score of the network is the logarithm of the determinant of this matrix:

$ s = log |K_H| $

A high score indicates that the images of the mini-batch are mapped to different linear regions; according to Mellor et al., such networks tend to reach a higher accuracy after training. The score was implemented with forward hooks on every ReLU layer.

=== Reproduction on NAS-Bench-201
Before using the score on EuroSAT, the implementation was validated on NAS-Bench-201, whose 15,625 architectures were rebuilt in PyTorch. Each architecture was then scored with a mini-batch of 128 CIFAR-10 images. The following quantities were compared with the paper: the Kendall rank correlation between the score and the final accuracy, and the accuracy of the network selected by NASWOT when $N$ = 10, 100 or 1,000 architectures are sampled.

=== Comparison with Other Search Strategies
Five other search strategies were executed on NAS-Bench-201, using the pre-computed accuracies as the result of the training:

- *Random Search (RS):* architectures are sampled uniformly and the best one is kept.
- *Regularised Evolution (REA):* a population of 20 architectures evolves by tournament selection (sample size 5) and single-edge mutation; the oldest individual is removed at each step @real2019rea.
- *Local Search (LS):* all neighbours of the current architecture (24 architectures that differ by one edge) are evaluated, and the search moves to the best one; a random restart is performed at a local optimum @white2021localsearch.
- *REINFORCE:* one categorical distribution per edge is learnt by policy gradient, with a moving-average baseline @williams1992reinforce.
- *Assisted REA (AREA):* NASWOT scores 1,000 random architectures and the 20 best ones form the initial population of REA @mellor2021naswot.

The cost of each strategy was measured by the number of architectures that had to be trained (the search budget), from 10 to 300. Each strategy was executed 200 times with different random seeds. The search used the CIFAR-10 validation accuracy @dong2020nasbench201.

=== Search on EuroSAT
A search space adapted to EuroSAT was defined using the same factors as in the manual study: 2 to 5 convolutional blocks, a kernel size of 3, 5 or 7 chosen independently for each block, a width of 16, 32 or 64 channels, batch normalisation or not, down-sampling by pooling or by stride, and residual connections or not. This space contains 8,640 different CNNs. First, the reliability of the proxies was measured on 51 random networks trained for five epochs. Then, 1,000 random networks were scored with NASWOT, and the three best ones were trained for five epochs. Finally, the winner was trained with the same recipe as the hand-designed CNN. Three networks selected by SynFlow and three random networks were trained for comparison.

== Evaluation Metrics
The models were evaluated by their test accuracy, their macro F1-score (the average over the ten classes of the harmonic mean of precision and recall) and their confusion matrix. Their cost was measured by the number of parameters and the inference latency in milliseconds per image. The reliability of a proxy was measured by Kendall's τ and Spearman's ρ, two rank correlations between the proxy score and the trained accuracy, and the cost of a search was measured by the GPU time or the number of architectures trained.

== Hardware and Software Setup
All the training experiments were implemented in Python 3.11 with PyTorch and torchvision. They were executed on Kaggle with a single NVIDIA T4 GPU (16 GB). The search-strategy comparison on NAS-Bench-201 required only table look-ups and was executed on a laptop CPU in 11 seconds. The main hyperparameters are listed in Appendix A.

= Results and Analysis

== Baseline CNN
@fig-baseline presents the learning curves of the baseline network. The training loss decreased continuously, whereas the validation loss reached its minimum after approximately ten epochs and then increased. This behaviour indicates that the network started to overfit the training data. The baseline reached a validation accuracy of 91.11% and a test accuracy of 90.15%, with a generalisation gap of 8.9 percentage points between the training and validation accuracies.

#figure(placement: none, image(F("nb1_curves.png"), width: 78%),
  caption: cap([Learning curves of the baseline CNN (loss and accuracy on the training and validation sets).], [Learning curves of the baseline CNN])) <fig-baseline>

== Effect of the Architecture
@tab-arch summarises the architecture study. Increasing the depth from three to five blocks improved the validation accuracy from 91.11% to 93.04%, while reducing the number of parameters from 2.19 to 1.24 million, since the deeper network has smaller feature maps before the classifier. In contrast, larger kernels degraded the performance: the 7×7 network reached only 79.95%. Replacing pooling by strided convolutions also reduced the accuracy (84.37%). Batch normalisation provided a moderate improvement (+0.79 point). When combined, five blocks of 3×3 convolutions with batch normalisation achieved 94.52%, which is 3.4 points above the baseline.

#figure(table(columns: (1fr, auto, auto, auto), align: (left, right, right, right),
  [Variant], [Parameters], [Val. accuracy (%)], [Gap (pt)],
  [Baseline (3 blocks, 3×3)], [2.19 M], [91.11], [8.87],
  [2 blocks], [4.22 M], [86.74], [13.21],
  [4 blocks], [1.44 M], [92.37], [7.32],
  [5 blocks], [1.24 M], [93.04], [6.17],
  [Kernel 5×5], [2.36 M], [89.16], [10.81],
  [Kernel 7×7], [2.61 M], [79.95], [15.87],
  [Valid padding], [1.28 M], [89.21], [10.52],
  [Strided convolution], [2.19 M], [84.37], [15.43],
  [One fully connected layer], [0.18 M], [90.74], [9.21],
  [Batch normalisation], [2.19 M], [91.90], [7.68],
  [*Combined (5 blocks + BN)*], [*1.24 M*], [*94.52*], [*4.89*],
), caption: cap([Effect of the architecture on the validation accuracy (SGD, 30 epochs, no augmentation).], [Effect of the architecture])) <tab-arch>

== Effect of the Optimiser and the Learning Rate
@tab-optim presents the results of the optimisation study, which was performed on the combined architecture. With a constant learning rate, Adam with a learning rate of 10#super[−3] obtained the highest validation accuracy (94.15%) and reached 90% after only six epochs. However, its final accuracy (92.22%) was lower than its best accuracy, which indicates that the training oscillated at the end. Adding a learning-rate scheduler solved this problem: both the step decay and the cosine annealing reached 95.85%. The cosine scheduler was retained, because its final accuracy was equal to its best accuracy.

#figure(table(columns: (1fr, auto, auto, auto), align: (left, right, right, right),
  [Configuration], [Best val. (%)], [Final val. (%)], [Epochs to 90%],
  [SGD, lr = 10#super[−2]], [93.28], [93.16], [10],
  [SGD, lr = 10#super[−3]], [93.31], [93.21], [9],
  [SGD, lr = 10#super[−4]], [90.52], [90.52], [23],
  [Adam, lr = 10#super[−2]], [93.04], [91.61], [12],
  [Adam, lr = 10#super[−3]], [94.15], [92.22], [6],
  [AdamW, lr = 10#super[−3]], [94.00], [94.00], [11],
  [Adam + step decay], [95.85], [95.61], [9],
  [*Adam + cosine annealing*], [*95.85*], [*95.85*], [*6*],
  [Adam + one-cycle], [95.53], [95.53], [8],
), caption: cap([Comparison of optimisers, learning rates and schedulers (combined architecture).], [Comparison of optimisers and schedulers])) <tab-optim>

== Effect of Data Augmentation
@tab-aug shows that geometric augmentations were beneficial. Flips alone increased the validation accuracy from 95.85% to 96.30% and reduced the generalisation gap from 3.9 to 1.9 points. This result can be explained by the nature of satellite images: unlike photographs, they have no natural "up" direction, so a flipped image is still a realistic example. Random crops and mixup provided small additional gains, and the best combination (flips, crops and mixup) reached 96.52%. In contrast, colour jitter and CutMix decreased the accuracy, probably because colour is an important cue for distinguishing classes such as Forest, SeaLake and AnnualCrop.

#figure(table(columns: (1fr, auto, auto), align: (left, right, right),
  [Augmentation], [Best val. (%)], [Gap (pt)],
  [None], [95.85], [3.90],
  [Flips], [96.30], [1.85],
  [Flips + crop], [96.44], [1.43],
  [Flips + crop + affine], [96.10], [0.96],
  [Flips + crop + affine + colour jitter], [95.65], [0.99],
  [*Flips + crop + mixup*], [*96.52*], [*1.21*],
  [Flips + crop + CutMix], [95.19], [0.91],
), caption: cap([Effect of data augmentation (combined architecture, Adam with cosine annealing).], [Effect of data augmentation])) <tab-aug>

On the test set, the final hand-designed CNN obtained an accuracy of 97.04%, which represents an improvement of 6.9 percentage points over the baseline, with 43% fewer parameters.

== Transfer Learning
@tab-transfer and @fig-transfer present the test accuracy of the transfer learning strategies for different amounts of training data. Full fine-tuning achieved the highest accuracy for every data fraction, with a maximum of 99.04% on the complete training set. Moreover, with only 5% of the data (947 images), the fine-tuned network reached 95.95%, whereas the CNN trained from scratch reached only 87.85%. The frozen network saturated at approximately 90%, which confirms that the ImageNet features of the last layers are not optimal for satellite images. Unfreezing only the last stage (layer4) recovered most of the gain.

#figure(table(columns: (1fr, auto, auto, auto, auto), align: (left, right, right, right, right),
  [Method (test accuracy, %)], [5%], [10%], [25%], [100%],
  [CNN from scratch], [87.85], [91.88], [94.91], [96.64],
  [ResNet-18, frozen], [87.51], [88.59], [89.80], [90.44],
  [ResNet-18, layer4 fine-tuned], [95.11], [95.73], [96.89], [97.90],
  [*ResNet-18, fully fine-tuned*], [*95.95*], [*96.86*], [*97.80*], [*99.04*],
), caption: cap([Test accuracy of transfer learning as a function of the fraction of training data.], [Transfer learning versus amount of data])) <tab-transfer>

#figure(image(F("nb5_transfer.png"), width: 80%),
  caption: cap([Test accuracy of the four strategies as a function of the amount of training data.], [Transfer learning versus amount of training data])) <fig-transfer>

The fine-tuned network also converged much faster: it reached 90% validation accuracy after a single epoch, whereas the scratch network required six epochs. However, this performance has a cost, since ResNet-18 contains 11.2 million parameters, which is nine times more than the hand-designed CNN.

== Reproduction of NASWOT on NAS-Bench-201
=== Correctness of the Implementation
The re-implemented networks had exactly the official number of parameters for all 300 architectures that were checked, and the best architecture of the benchmark had a CIFAR-10 test accuracy of 94.37%, which matches the official value. This confirms that the search space was reproduced correctly.

=== Correlation Between Score and Accuracy
@tab-tau compares the Kendall correlation obtained in this study with the values reported by Mellor et al. The correlations were slightly higher than the published values, by 0.03 to 0.05. This small difference can be attributed to the random choice of the mini-batch and of the sampled architectures. @fig-scatter shows the relation between the score and the accuracy for all 15,625 architectures.

#figure(table(columns: (1fr, auto, auto, auto), align: (left, right, right, right),
  [Dataset], [This study], [Mellor et al. (2021)], [Difference],
  [CIFAR-10], [0.602], [0.574], [+0.028],
  [CIFAR-100], [0.640], [0.611], [+0.029],
  [ImageNet16-120#super[\*]], [0.600], [0.549], [+0.051],
), caption: cap([Kendall's τ between the NASWOT score and the final validation accuracy (1,000 architectures). #super[\*]Approximated with CIFAR-100 images at 16×16 pixels.], [Kendall's τ: this study versus the paper])) <tab-tau>

#figure(image(F("nb61_scatter.png"), width: 50%),
  caption: cap([NASWOT score at initialisation versus CIFAR-10 validation accuracy after training, for the 15,625 architectures of NAS-Bench-201.], [NASWOT score versus CIFAR-10 accuracy on NAS-Bench-201])) <fig-scatter>

The scatter plot shows a clear positive relation, but also a large dispersion among the best architectures. Consequently, NASWOT is able to discard poor architectures, but it cannot reliably distinguish the very best architecture from other good ones. The score was also stable with respect to the mini-batch: the Kendall correlation between the rankings obtained with two different mini-batches was 0.99. Scoring one architecture required 160 milliseconds.

=== Search Results
@tab-repro compares the accuracy of the architecture selected by NASWOT with the values reported in the paper. For $N$ = 10 and $N$ = 100, the differences on CIFAR-10 and CIFAR-100 were below 0.1 percentage point. Therefore, the NASWOT search was considered successfully reproduced.

#let rep = json("../../results/NB6_1_NASBench201_Reproduction/NB6_1_reproduction.json").search
#figure(table(columns: (1fr, auto, auto, auto), align: (left, right, right, right),
  [Method], [CIFAR-10 test], [CIFAR-100 test], [ImageNet16 test#super[\*]],
  ..("NASWOT (N=10)", "NASWOT (N=100)", "Random").map(k => (
    [#k, this study], ..(1, 3, 5).map(i => [#pm(rep.at(k).ours_mean.at(i), rep.at(k).ours_std.at(i))]),
    [#k, paper], ..(1, 3, 5).map(i => [#pm(rep.at(k).paper.at(i).at(0), rep.at(k).paper.at(i).at(1))]),
  )).flatten(),
), caption: cap([Test accuracy (%) of the selected architecture, mean ± standard deviation over 500 runs. #super[\*]Approximated with CIFAR-100 images.], [NASWOT search: this study versus the paper])) <tab-repro>

== Comparison of NAS Strategies on NAS-Bench-201
@tab-strategies presents the accuracy obtained by the six search strategies after 100 trained architectures, together with the training-free NASWOT. @fig-anytime shows how the accuracy of each strategy evolves with the search budget.

#let S = D.search
#figure(table(columns: (1fr, auto, auto, auto, auto), align: (left, right, right, right, right),
  [Strategy], [Trained nets], [CIFAR-10], [CIFAR-100], [ImageNet16],
  ..S.keys().map(k => ([#k], [100], ..(1, 3, 5).map(i => [#pm(S.at(k).at("100").mean.at(i), S.at(k).at("100").std.at(i))]))).flatten(),
  ..("10", "100", "1000").map(n => ([NASWOT (N = #n)], [0], ..(1, 3, 5).map(i => [#pm(D.naswot.at(n).mean.at(i), D.naswot.at(n).std.at(i))]))).flatten(),
  [Best architecture of the space], [–], ..(1, 3, 5).map(i => [#r2(D.best_in_space.at(i))]),
), caption: cap([Test accuracy (%) of the architecture selected by each strategy on NAS-Bench-201 (mean ± standard deviation over 200 runs; search on the CIFAR-10 validation set).], [Comparison of search strategies on NAS-Bench-201])) <tab-strategies>

#figure(image(E("en_anytime.png"), width: 82%),
  caption: cap([CIFAR-10 test accuracy of the best architecture found as a function of the number of architectures trained (mean of 200 runs; shaded area: 95% confidence interval).], [Accuracy of each search strategy versus search budget])) <fig-anytime>

Several observations can be made. First, all training-based strategies outperformed NASWOT when they were allowed to train 100 architectures: regularised evolution and assisted evolution reached 94.1% on CIFAR-10, which is only 0.25 point below the best architecture of the space. Second, NASWOT without any training (92.9%) was equivalent to a random search with approximately ten trained architectures. Third, local search was the weakest strategy with a small budget, because it spends its first evaluations on the neighbours of a single random architecture; however, it caught up with evolution after approximately 150 evaluations, which is consistent with White et al. @white2021localsearch.

The most interesting result concerns the combination of both approaches. As shown in @fig-anytime, assisted REA, which uses NASWOT to select its initial population, was clearly superior with small budgets: with only ten trained architectures, it reached 93.5% on CIFAR-10, against 93.0% for regular evolution and random search. As the budget increased, the advantage disappeared, since the evolution itself found good architectures.

In the context of the whole search space, the distribution of accuracies is highly skewed: most architectures reach between 85% and 94%, but a non-negligible number of architectures fail completely. A random choice (86.6% on average) frequently selects such a poor architecture, whereas NASWOT avoids them almost systematically.

== Comparison with Published NAS Methods
@tab-published compares NASWOT with the results published for ten other NAS methods on the same benchmark @mellor2021naswot @dong2020nasbench201. Weight-sharing methods showed a highly variable performance. In particular, DARTS and ENAS converged to a degenerate architecture with only 54.3% accuracy on CIFAR-10. In contrast, NASWOT reached 92.4% to 93.0% in 3 to 306 seconds, that is, 40 to 4,000 times faster than the training-based methods, which require 12,000 seconds.

#figure(table(columns: (1fr, auto, auto, auto), align: (left, left, right, right),
  [Method], [Family], [Search time (s)], [CIFAR-10 test (%)],
  [REA], [Training-based], [12,000], [93.92 ± 0.30],
  [Random search], [Training-based], [12,000], [93.70 ± 0.36],
  [REINFORCE], [Training-based], [12,000], [93.85 ± 0.37],
  [BOHB], [Training-based], [12,000], [93.61 ± 0.52],
  [RSPS], [Weight sharing], [7,587], [87.66 ± 1.69],
  [DARTS-V1], [Weight sharing], [10,890], [54.30 ± 0.00],
  [DARTS-V2], [Weight sharing], [29,902], [54.30 ± 0.00],
  [GDAS], [Weight sharing], [28,926], [93.51 ± 0.13],
  [SETN], [Weight sharing], [31,010], [86.19 ± 4.63],
  [ENAS], [Weight sharing], [13,315], [54.30 ± 0.00],
  [NASWOT (N = 10)], [Training-free], [3], [92.44 ± 1.13],
  [NASWOT (N = 100)], [Training-free], [30], [92.81 ± 0.99],
  [NASWOT (N = 1000)], [Training-free], [306], [92.96 ± 0.81],
), caption: cap([Published results of NAS methods on NAS-Bench-201 (Mellor et al., 2021, Table 2; search times on a single GTX 1080 Ti GPU).], [Published results of NAS methods on NAS-Bench-201])) <tab-published>

== Architecture Search on EuroSAT
=== Reliability of the Proxies
@tab-proxies presents the Spearman correlation between each proxy and the accuracy of 51 EuroSAT networks trained for five epochs. The correlations were weaker than on NAS-Bench-201. NASWOT obtained a moderate correlation (0.43), and the gradient norm and SNIP obtained slightly higher values. In contrast, SynFlow and the number of parameters were not informative on this search space, which shows that larger networks are not necessarily better on EuroSAT.

#let corr = json("../../results/NB6_2_EuroSAT_ZeroCost_NAS/NB6_2_correlation_study.json").correlations
#figure(table(columns: (1fr, auto, auto), align: (left, right, right),
  [Proxy], [Spearman ρ (EuroSAT)], [Spearman ρ (NAS-Bench-201)],
  [NASWOT], [#r2(corr.naswot.at(0))], [0.81],
  [SynFlow], [#r2(corr.synflow.at(0))], [0.80],
  [SNIP], [#r2(corr.snip.at(0))], [0.65],
  [Gradient norm], [#r2(corr.grad_norm.at(0))], [0.65],
  [Number of parameters], [#r2(corr.params.at(0))], [0.76],
), caption: cap([Rank correlation between each zero-cost proxy and the trained accuracy on the two search spaces.], [Correlation of the zero-cost proxies])) <tab-proxies>

=== Search Results
Scoring 1,000 random networks with NASWOT required 153 seconds. @tab-eurosat-search compares the three networks selected by NASWOT with those selected by SynFlow and with three random networks, after five epochs of training. The NASWOT selection obtained the highest mean accuracy (90.8%), against 88.0% for SynFlow and 83.3% for the random networks.

#figure(table(columns: (1fr, auto, auto), align: (left, right, right),
  [Selection method (top-3)], [Mean val. accuracy, 5 epochs (%)], [Mean parameters],
  [*NASWOT*], [*90.76*], [*3.30 M*],
  [SynFlow], [87.96], [5.23 M],
  [Random], [83.32], [6.89 M],
  [Hand-designed CNN (reference)], [87.7], [1.24 M],
), caption: cap([Five-epoch validation accuracy of the networks selected on the EuroSAT search space.], [Networks selected on the EuroSAT search space])) <tab-eurosat-search>

The best network selected by NASWOT contained five blocks with kernel sizes 5, 3, 3, 3 and 3, a width of 64 channels, batch normalisation, max-pooling and residual connections. After a complete training with the same recipe as the hand-designed CNN, it reached a test accuracy of 97.43%. @tab-eurosat-final compares it with the hand-designed network.

#figure(table(columns: (1fr, auto, auto), align: (left, right, right),
  [Criterion], [Hand-designed CNN], [NASWOT winner],
  [Test accuracy (%)], [96.72], [*97.43*],
  [Parameters], [*1.24 M*], [1.99 M],
  [Inference latency (ms)], [*0.76*], [1.31],
  [GPU time spent on the design], [203 min], [*17 min*],
), caption: cap([Comparison between the hand-designed CNN and the network found by NASWOT (same training recipe, retrained in NB6.2).], [Hand-designed CNN versus NASWOT winner])) <tab-eurosat-final>

The searched network was 0.7 point more accurate than the hand-designed one, and the design required twelve times less GPU time. Interestingly, the search rediscovered the main conclusions of the manual study (deep networks, small kernels and batch normalisation) and additionally selected residual connections, which had not been tested manually.

== Final Comparison of All Models
All 50 checkpoints were reloaded and evaluated on the same 4,050 test images. @tab-final presents the four representative models, and @fig-pareto shows the trade-off between accuracy and latency.

#figure(table(columns: (1fr, auto, auto, auto, auto), align: (left, right, right, right, right),
  [Model], [Accuracy (%)], [Macro F1 (%)], [Parameters], [Latency (ms)],
  [Baseline CNN], [90.15], [89.76], [2.19 M], [*0.34*],
  [Hand-designed CNN], [97.04], [96.97], [*1.24 M*], [0.79],
  [NASWOT winner], [97.43], [97.36], [1.99 M], [1.27],
  [ResNet-18, fully fine-tuned], [*99.04*], [*98.99*], [11.18 M], [2.23],
), caption: cap([Final comparison of the representative models on the common test set (NB7).], [Final comparison of the representative models])) <tab-final>

#figure(image(F("nb7_pareto.png"), width: 68%),
  caption: cap([Test accuracy versus inference latency for the 50 trained models.], [Accuracy versus latency of the 50 models])) <fig-pareto>

No single model was the best on every criterion. The fine-tuned ResNet-18 was the most accurate model, whereas the scratch CNNs were the fastest and the smallest. The network found by NASWOT occupied an intermediate position.

== Error Analysis
The confusion matrices of the hand-designed CNN and of the fine-tuned ResNet-18 were also analysed. The hand-designed CNN misclassified 120 of the 4,050 test images, and the ResNet-18 misclassified 39. In both cases, most errors occurred between the agricultural classes (PermanentCrop, HerbaceousVegetation, AnnualCrop and Pasture), whose images are similar green textures at a resolution of 64×64 pixels. Furthermore, the two models made different errors, and only 14 images were misclassified by all three main models. A visual inspection of these images revealed that they mostly contain mixed land uses, for example a field crossed by a road, for which the label itself is ambiguous.

= Discussion and Recommendations

== Interpretation of the Results
The results demonstrate that each of the three approaches has a distinct domain of application. Manual design produced a compact and fast network (1.24 million parameters, 0.79 ms per image), but it required more than three hours of GPU time and a large number of decisions. Transfer learning produced the most accurate model and was by far the best option with limited data; however, its size and latency make it less suitable for embedded deployment. Training-free search produced, in a few minutes, a network that was more accurate than the manual design, which indicates that the score captures useful information about the trainability of an architecture.

The comparison on NAS-Bench-201 clarifies the role of NASWOT. It is not a replacement for training-based search, since evolution with 100 trained networks consistently found better architectures. Nevertheless, NASWOT is an excellent filter: it avoids the poor regions of the search space at almost no cost, and it is most useful when combined with a training-based method, as shown by assisted evolution with small budgets.

In the real-world context of satellite monitoring, these findings mean that the choice of approach should depend on the deployment constraints. When the model is executed in a data centre, a fine-tuned pretrained network is the most appropriate choice. When the model must run on limited hardware, a training-free search followed by a short training-based refinement offers a good compromise between accuracy and design cost.

== Limitations
The following limitations should be considered when interpreting the results:

- *Single seed:* each configuration of the manual study was trained only once. Repeated runs vary by approximately 0.3 to 1 point, so only large effects can be considered conclusive.
- *Short training for the EuroSAT proxies:* the correlation study on EuroSAT used a five-epoch training as ground truth, which is a noisy estimate of the final accuracy.
- *ImageNet16-120 approximation:* this dataset was not available on Kaggle, and the scores were computed with resized CIFAR-100 images.
- *Simulated search cost:* on NAS-Bench-201, the training of an architecture was replaced by a table look-up, and the cost was measured by the number of architectures trained rather than by actual GPU time.
- *Single dataset:* the conclusions on EuroSAT have not been verified on other remote sensing datasets or on multispectral images.

== Recommendations
Based on these results, the following recommendations are proposed:

+ For satellite image classification without strict size constraints, fine-tune a pretrained network rather than designing a CNN from scratch, especially when fewer than a few thousand labelled images are available.
+ Use orientation-invariant augmentations (flips and rotations) for overhead imagery, and avoid strong colour transformations.
+ Use a training-free score such as NASWOT to filter the search space before any training, and then train only the best candidates or use them to initialise an evolutionary search.
+ Validate a zero-cost proxy on a small sample of trained networks before relying on it in a new search space, since its correlation may be weaker than on public benchmarks.
+ In future work, repeat the experiments with several random seeds, extend the study to the 13 spectral bands of EuroSAT, and evaluate hardware-aware search with a latency constraint.

= Conclusion
This project aimed to compare three approaches for building a convolutional network that classifies satellite images: manual design, transfer learning and training-free neural architecture search. A baseline CNN was improved step by step through its architecture, its optimiser and its data augmentation, an ImageNet-pretrained ResNet-18 was fine-tuned with different amounts of data, and the NASWOT score was reproduced on NAS-Bench-201, compared with five search strategies and finally applied to EuroSAT.

The manual study increased the test accuracy from 90.15% to 97.04%, and the fine-tuned ResNet-18 obtained the highest accuracy of 99.04%. The reproduction confirmed the published NASWOT results within 0.1 percentage point, and the comparison of search strategies showed that NASWOT is most valuable as a fast filter or as an initialisation for evolutionary search. On EuroSAT, the network found by NASWOT reached 97.43% with twelve times less design time than the manual approach.

In summary, training-free architecture search constitutes a practical and inexpensive first step for the design of compact models, while transfer learning remains the most accurate solution when the size of the model is not constrained.

// ===================================================================== references
#show bibliography: set par(spacing: 0.9em, leading: 0.7em)
#bibliography("refs.bib", title: [References], style: "apa", full: false)

// ===================================================================== appendices
#set figure(placement: none)
#heading(level: 1, numbering: none)[Appendices]

#heading(level: 2, numbering: none)[Appendix A: Training Hyperparameters]
#figure(table(columns: (1fr, auto, auto), align: (left, left, left),
  [Hyperparameter], [Hand-designed CNN], [ResNet-18 (fine-tuned)],
  [Input size], [64 × 64], [128 × 128],
  [Optimiser], [Adam], [Adam],
  [Learning rate], [10#super[−3]], [10#super[−4] (backbone), 10#super[−3] (head)],
  [Scheduler], [Cosine annealing], [Cosine annealing],
  [Batch size], [64], [64],
  [Epochs], [30], [15 (100% of data) to 60 (5%)],
  [Augmentation], [Flips, crop, mixup], [Flips, crop],
  [Loss function], [Cross-entropy], [Cross-entropy],
  [Model selection], [Best validation accuracy], [Best validation accuracy],
), caption: cap([Main hyperparameters of the two final models.], [Main hyperparameters of the two final models])) <tab-hparams>

#heading(level: 2, numbering: none)[Appendix B: EuroSAT Search Space]
#figure(table(columns: (1fr, 1fr), align: (left, left),
  [Factor], [Possible values],
  [Number of convolutional blocks], [2, 3, 4 or 5],
  [Kernel size (chosen per block)], [3 × 3, 5 × 5 or 7 × 7],
  [Width (channels of the first block)], [16, 32 or 64],
  [Batch normalisation], [Yes or no],
  [Down-sampling], [Max-pooling or strided convolution],
  [Residual connections], [Yes or no],
  [Total number of architectures], [8,640],
), caption: cap([Factors of the EuroSAT search space used for the architecture search.], [Factors of the EuroSAT search space])) <tab-space>
