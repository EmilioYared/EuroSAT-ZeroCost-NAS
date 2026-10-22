"""Run a project notebook on Kaggle (GPU) and download the executed notebook + outputs.

Usage:  python kaggle_run.py NB0_Setup_Data [--no-wait]

The notebook folder must contain <folder>.ipynb and kernel-metadata.json
(dataset_sources / kernel_sources / enable_gpu are read from it).
The notebook is embedded in a small runner script, executed on Kaggle with nbconvert,
and the executed .ipynb is saved to /kaggle/working so that it can be downloaded
(Kaggle does not return the executed notebook through the CLI otherwise).
Everything ends up in <folder>/output/.
"""
import base64
import json
import os
import shutil
import subprocess
import sys
import time

RUNNER = r'''
import base64, os, subprocess, sys
nb_name = "{name}.ipynb"
with open(nb_name, "wb") as f:
    f.write(base64.b64decode("{payload}"))
cmd = [sys.executable, "-m", "jupyter", "nbconvert", "--to", "notebook", "--execute",
       "--ExecutePreprocessor.timeout={cell_timeout}", "--ExecutePreprocessor.kernel_name=python3",
       "--output", "/kaggle/working/" + nb_name, nb_name]
print(" ".join(cmd), flush=True)
ret = subprocess.call(cmd)
print("nbconvert exit code:", ret, flush=True)
sys.exit(ret)
'''


def resolve_source(src, folder):
    if not src.startswith("@"):
        return src
    last_run = os.path.join(os.path.dirname(folder), src[1:], "last_run.txt")
    return open(last_run).read().strip()


def kaggle(*args):
    return subprocess.run([sys.executable, "-m", "kaggle", *args], capture_output=True, text=True)


def main():
    folder = os.path.abspath(sys.argv[1])
    name = os.path.basename(folder)
    wait = "--no-wait" not in sys.argv
    meta = json.load(open(os.path.join(folder, "kernel-metadata.json")))

    build = os.path.join(folder, "_build")
    shutil.rmtree(build, ignore_errors=True)
    os.makedirs(build)
    payload = base64.b64encode(open(os.path.join(folder, name + ".ipynb"), "rb").read()).decode()
    with open(os.path.join(build, "run.py"), "w") as f:
        f.write(RUNNER.format(name=name, payload=payload, cell_timeout=meta.get("cell_timeout", 3600)))

    run_meta = {k: v for k, v in meta.items() if k != "cell_timeout"}
    # unique name per run: a stuck session on Kaggle can never block a new run
    stamp = time.strftime("%m%d-%H%M")
    run_meta["id"] = meta["id"] + "-run-" + stamp
    run_meta["title"] = meta["title"] + " run " + stamp  # Kaggle derives the URL slug from the title
    # kernel_sources written as "@NB0_Setup_Data" -> latest run of that notebook folder
    run_meta["kernel_sources"] = [resolve_source(k, folder) for k in meta.get("kernel_sources", [])]
    run_meta["code_file"] = "run.py"
    run_meta["kernel_type"] = "script"
    json.dump(run_meta, open(os.path.join(build, "kernel-metadata.json"), "w"), indent=2)

    r = kaggle("kernels", "push", "-p", build)
    print(r.stdout.strip(), r.stderr.strip(), flush=True)
    if r.returncode != 0:
        return
    with open(os.path.join(folder, "last_run.txt"), "w") as f:
        f.write(run_meta["id"])
    if not wait:
        return

    status = ""
    while True:
        time.sleep(30)
        status = kaggle("kernels", "status", run_meta["id"]).stdout.strip()
        print(time.strftime("%H:%M:%S"), status, flush=True)
        if any(s in status for s in ("COMPLETE", "ERROR", "CANCEL")):
            break

    out = os.path.join(folder, "output")
    shutil.rmtree(out, ignore_errors=True)
    os.makedirs(out)
    r = kaggle("kernels", "output", run_meta["id"], "-p", out)
    print(r.stdout.strip(), r.stderr.strip())
    # print the tail of the log (stdout + stderr) to see errors quickly
    log_file = os.path.join(out, run_meta["id"].split("/")[1] + ".log")
    if os.path.exists(log_file):
        log = json.load(open(log_file, encoding="utf-8"))
        text = "".join(e.get("data", "") for e in log)
        print("----- log tail -----")
        print(text[-3000:])


if __name__ == "__main__":
    main()
