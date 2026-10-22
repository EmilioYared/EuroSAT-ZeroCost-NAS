# Checkpoints

The 50 trained models (about 730 MB) are too large for the repository.
Download `checkpoints.zip` from the [latest release](../../../releases) and unzip it here.

| Prefix | Notebook | Models |
|---|---|---|
| `NB1_` | Baseline CNN | 1 |
| `NB2_` | Architecture variations | 12 |
| `NB3_` | Optimisers and LR schedulers | 12 |
| `NB4_` | Data augmentation | 7 |
| `NB5_` | Transfer learning (ResNet-18 frozen / partial / full, scratch CNN; 5–100% of the data) | 16 |
| `NB6_2_` | Hand-designed CNN and NASWOT winner | 2 |

Load one with `model.load_state_dict(torch.load(path, map_location="cpu"))` after building the matching architecture from its notebook.
