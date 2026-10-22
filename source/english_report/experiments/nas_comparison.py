"""Comparison of NAS search strategies on the NAS-Bench-201 tabular benchmark.

Every architecture of the space (15,625) has a known accuracy (NB6.0) and a NASWOT score
computed by us (NB6.1), so a "training" is a table look-up and every strategy can be run
hundreds of times on a CPU. Budget = number of architectures trained (queried).
All searches use the CIFAR-10 validation accuracy (as in Dong & Yang, 2020); the selected
architecture is then reported on the 3 datasets.
"""
import json
import time
import numpy as np
import pandas as pd

SRC = "../../results/NB6_1_NASBench201_Reproduction/NB6_1_nasbench201_naswot_scores.csv"
OUT = "experiments/nas_comparison.json"
OPS = ["none", "skip_connect", "nor_conv_1x1", "nor_conv_3x3", "avg_pool_3x3"]
COLS = ["cifar10_valid", "cifar10_test", "cifar100_valid", "cifar100_test", "imagenet16_valid", "imagenet16_test"]
RUNS = 200
BUDGETS = [10, 25, 50, 100, 200, 300]
MAXB = max(BUDGETS)

df = pd.read_csv(SRC)
ACC = df[COLS].values
VAL = ACC[:, 0]
SCORE = df["naswot_cifar10"].values
N = len(df)


def encode(arch):
    # |op~0|+|op~0|op~1|+|op~0|op~1|op~2|  ->  6 op indices
    return tuple(OPS.index(tok.split("~")[0]) for tok in arch.replace("+", "").split("|") if tok)


CODE = [encode(a) for a in df["arch"]]
INDEX = {c: i for i, c in enumerate(CODE)}


def mutate(i, rng):
    c = list(CODE[i])
    e = rng.integers(6)
    c[e] = rng.choice([o for o in range(5) if o != c[e]])
    return INDEX[tuple(c)]


def neighbours(i):
    out = []
    for e in range(6):
        for o in range(5):
            if o != CODE[i][e]:
                c = list(CODE[i])
                c[e] = o
                out.append(INDEX[tuple(c)])
    return out


# each strategy returns the list of queried architectures (in order), length MAXB
def random_search(rng):
    return list(rng.choice(N, MAXB, replace=False))


def rea(rng, init=None, pop=20, sample=5):
    # regularised evolution (Real et al., 2019): tournament selection + ageing
    hist = list(init) if init is not None else list(rng.choice(N, pop, replace=False))
    population = list(hist[:pop])
    while len(hist) < MAXB:
        cand = rng.choice(len(population), sample, replace=False)
        parent = population[max(cand, key=lambda k: VAL[population[k]])]
        child = mutate(parent, rng)
        hist.append(child)
        population.append(child)
        population.pop(0)  # remove the oldest
    return hist[:MAXB]


def area(rng, n_scored=1000, pop=20):
    # assisted REA (Mellor et al., 2021): NASWOT picks the starting population
    pool = rng.choice(N, n_scored, replace=False)
    init = pool[np.argsort(-SCORE[pool])[:pop]]
    return rea(rng, init=init, pop=pop)


def local_search(rng):
    hist = []
    cur = rng.integers(N)
    hist.append(cur)
    while len(hist) < MAXB:
        nb = [j for j in neighbours(cur)]
        rng.shuffle(nb)
        best = cur
        for j in nb:
            hist.append(j)
            if VAL[j] > VAL[best]:
                best = j
            if len(hist) >= MAXB:
                break
        if best == cur:  # local optimum: restart
            cur = rng.integers(N)
            hist.append(cur)
        else:
            cur = best
    return hist[:MAXB]


def reinforce(rng, lr=0.05, momentum=0.9):
    # Williams (1992): one categorical policy per edge, moving-average baseline
    logits = np.zeros((6, 5))
    baseline, hist = None, []
    while len(hist) < MAXB:
        p = np.exp(logits) / np.exp(logits).sum(1, keepdims=True)
        c = tuple(rng.choice(5, p=p[e]) for e in range(6))
        i = INDEX[c]
        hist.append(i)
        r = VAL[i] / 100
        baseline = r if baseline is None else momentum * baseline + (1 - momentum) * r
        for e in range(6):
            g = -p[e]
            g[c[e]] += 1
            logits[e] += lr * (r - baseline) * g * 10
    return hist


def naswot(rng, n):
    pool = rng.choice(N, n, replace=False)
    return pool[np.argmax(SCORE[pool])]


def best_so_far(hist, b):
    h = hist[:b]
    return h[int(np.argmax(VAL[h]))]


STRATS = {"Random Search (RS)": random_search, "Regularised Evolution (REA)": rea,
          "Local Search (LS)": local_search, "REINFORCE": reinforce, "Assisted REA (AREA)": area}

results, curves = {}, {}
t0 = time.time()
for name, fn in STRATS.items():
    rng = np.random.default_rng(0)
    finals = {b: [] for b in BUDGETS}
    curve = np.zeros((RUNS, MAXB))
    for r in range(RUNS):
        hist = fn(rng)
        run_best = np.maximum.accumulate(VAL[hist])
        # test accuracy of the best-validation architecture after each query
        idx_best = [hist[int(np.argmax(VAL[hist[:k + 1]]))] for k in range(MAXB)]
        curve[r] = ACC[idx_best, 1]
        for b in BUDGETS:
            finals[b].append(ACC[best_so_far(hist, b)])
    results[name] = {str(b): {"mean": np.mean(finals[b], 0).tolist(), "std": np.std(finals[b], 0).tolist()} for b in BUDGETS}
    curves[name] = {"mean": curve.mean(0).tolist(), "std": curve.std(0).tolist()}
    print("%-28s B=100: C10 test %.2f +- %.2f" % (name, results[name]["100"]["mean"][1], results[name]["100"]["std"][1]))

naswot_res = {}
for n in [10, 100, 1000]:
    rng = np.random.default_rng(0)
    sel = np.array([ACC[naswot(rng, n)] for _ in range(RUNS * 5)])
    naswot_res[str(n)] = {"mean": sel.mean(0).tolist(), "std": sel.std(0).tolist()}
    print("NASWOT N=%-5d C10 test %.2f +- %.2f" % (n, naswot_res[str(n)]["mean"][1], naswot_res[str(n)]["std"][1]))

json.dump({"runs": RUNS, "budgets": BUDGETS, "columns": COLS, "search": results, "curves": curves,
           "naswot": naswot_res, "best_in_space": ACC[np.argmax(VAL)].tolist(),
           "ms_per_naswot_score": 160.4}, open(OUT, "w"), indent=1)
print("done in %.0f s" % (time.time() - t0))
