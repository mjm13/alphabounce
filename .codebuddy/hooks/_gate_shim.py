import sys

# Shim: read gate args from a UTF-8 sidecar to avoid GBK argv corruption on Windows.
# Sidecar format (UTF-8):
#   line 1: flag, e.g. --check-release  (optional extra flags space-separated)
#   line 2: requirement path
SHIM_DIR = r"d:\Project\SELF\alphabounce\.codebuddy\hooks"
sys.path.insert(0, SHIM_DIR)

with open(r"d:\tmp_gate_args.txt", "r", encoding="utf-8-sig") as f:
    lines = [ln.strip() for ln in f if ln.strip()]

flag_tokens = lines[0].split()
req_path = lines[1]

sys.argv = [r"pipeline_guard.py"] + flag_tokens + ["--req", req_path]

import pipeline_guard

raise SystemExit(pipeline_guard.main())
