#!/usr/bin/env python3
"""Push every model in MANIFEST.json to hf.co/renaudb1999/le-harnais-<name>.

Requires a HF token WITH WRITE SCOPE. The token already cached on this box is
read-only; create a write token at https://huggingface.co/settings/tokens and either:
    hf auth login                  # paste the write token, or
    export HF_TOKEN=hf_xxx         # then run this script

Uploads (per model): bf16 safetensors (from local_safetensors) + GGUF (from
local_gguf) + the generated README model card. Visibility comes from the manifest
(heroes public, ablations/smoke private). Resumable — re-running skips unchanged files.

Usage:
    python upload_to_hf.py            # all models
    python upload_to_hf.py ft-counsel ft-agentworld-8b   # a subset
    python upload_to_hf.py --dry-run  # print what would happen, no network
"""
import json, os, sys
from huggingface_hub import HfApi

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
MANIFEST = json.load(open(os.path.join(HERE, "MANIFEST.json")))

def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    dry = "--dry-run" in sys.argv
    api = HfApi()
    if not dry:
        who = api.whoami()
        role = who.get("auth", {}).get("accessToken", {}).get("role", "?")
        if role != "write":
            sys.exit(f"token role is '{role}', need 'write'. Run `hf auth login` with a write token "
                     f"or set HF_TOKEN. (see this file's docstring)")
    models = MANIFEST["models"]
    names = args or list(models)
    for name in names:
        m = models[name]
        repo, private = m["repo_id"], (m["visibility"] != "public")
        sdir = os.path.join(ROOT, m["local_safetensors"])
        gdir = os.path.join(ROOT, m["local_gguf"])
        print(f"== {name} -> {repo} ({'private' if private else 'PUBLIC'})")
        if dry:
            print(f"   safetensors: {sdir}\n   gguf: {gdir}"); continue
        api.create_repo(repo, repo_type="model", private=private, exist_ok=True)
        # safetensors + tokenizer + configs + README card
        api.upload_folder(repo_id=repo, folder_path=sdir,
                          ignore_patterns=["checkpoint-*", "*.bin"])
        # GGUF quants (into the same repo root)
        if os.path.isdir(gdir):
            api.upload_folder(repo_id=repo, folder_path=gdir, allow_patterns=["*.gguf"])
        print(f"   done: https://huggingface.co/{repo}")

if __name__ == "__main__":
    main()
