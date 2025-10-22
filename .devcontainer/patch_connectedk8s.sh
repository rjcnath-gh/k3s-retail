#!/usr/bin/env bash
set -euo pipefail

# Idempotent patch to ensure connectedk8s extension uses its vendored azure package
EXT_DIR="${HOME}/.azure/cliextensions/connectedk8s"
if [ ! -d "${EXT_DIR}" ]; then
  echo "connectedk8s extension not installed at ${EXT_DIR}, skipping patch"
  exit 0
fi

backup() {
  local f="$1"
  if [ -f "$f" ]; then
    local b="$f.bak.$(date +%s)"
    cp -n "$f" "$b" && echo "backup $f -> $b"
  fi
}

patch_init_py() {
  local f="$EXT_DIR/azext_connectedk8s/__init__.py"
  if [ -f "$f" ]; then
    if ! grep -q "Ensure the extension root (parent dir of this package) is first on sys.path" "$f"; then
      backup "$f"
      python3 - "$f" <<'PY'
import sys
fpath = sys.argv[1]
txt = open(fpath, 'r', encoding='utf-8').read()
ins = (
    "import sys\n"
    "import os\n\n"
    "# Ensure the extension root (parent dir of this package) is first on sys.path\n"
    "_EXT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))\n"
    "if _EXT_ROOT not in sys.path:\n"
    "    sys.path.insert(0, _EXT_ROOT)\n\n"
)
if 'Ensure the extension root (parent dir of this package) is first on sys.path' not in txt:
    if 'from __future__ import annotations' in txt:
        txt = txt.replace('from __future__ import annotations\n', 'from __future__ import annotations\n\n' + ins)
    else:
        txt = ins + txt
    open(fpath, 'w', encoding='utf-8').write(txt)
print('patched', fpath)
PY
    fi
  fi
}

patch_custom_py() {
  local f="$EXT_DIR/azext_connectedk8s/custom.py"
  if [ -f "$f" ]; then
    if ! grep -q "Ensure the extension's vendored packages (the parent extension folder) are" "$f"; then
      backup "$f"
      python3 - "$f" <<'PY'
import sys
fpath = sys.argv[1]
txt = open(fpath, 'r', encoding='utf-8').read()
ins = (
    "import sys\n"
    "import os\n\n"
    "# Ensure the extension's vendored packages (the parent extension folder) are\n"
    "# preferred on sys.path so vendored 'azure' packages are imported instead of the global /opt/az packages.\n"
    "_THIS_EXT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))\n"
    "if _THIS_EXT_ROOT not in sys.path:\n"
    "    sys.path.insert(0, _THIS_EXT_ROOT)\n\n"
)
if ins.strip() not in txt:
    if 'from __future__ import annotations' in txt:
        txt = txt.replace('from __future__ import annotations\n', 'from __future__ import annotations\n\n' + ins)
    else:
        txt = ins + txt
    open(fpath, 'w', encoding='utf-8').write(txt)
print('patched', fpath)
PY
    fi
  fi
}

create_shim() {
  local shim_dir="$EXT_DIR/azext_connectedk8s/azure"
  local shim_file="$shim_dir/__init__.py"
  if [ ! -d "$shim_dir" ]; then
    mkdir -p "$shim_dir"
  fi
  if [ ! -f "$shim_file" ]; then
    cat > "$shim_file" <<'PY'
import os

# Shim package to expose the extension's vendored `azure` package under
# the `azext_connectedk8s.azure` namespace. This lets vendored SDK modules
# import `azext_connectedk8s.azure.mgmt...` while actually loading the
# extension-provided `azure/...` code located at ../azure.
_THIS = os.path.abspath(os.path.dirname(__file__))
# extension root: two levels up from this file
_EXT_ROOT = os.path.abspath(os.path.join(_THIS, '..', '..'))
_VENDORED_AZURE = os.path.join(_EXT_ROOT, 'azure')
if os.path.isdir(_VENDORED_AZURE):
    # Prepend vendored azure to this package's __path__ so imports under
    # azext_connectedk8s.azure.* resolve to files in ../azure
    __path__.insert(0, _VENDORED_AZURE)
PY
    echo "created shim $shim_file"
  fi
}

patch_clients() {
  local c1="$EXT_DIR/azext_connectedk8s/vendored_sdks/preview_2025_08_01/_client.py"
  local c2="$EXT_DIR/azext_connectedk8s/vendored_sdks/preview_2025_08_01/aio/_client.py"
  for f in "$c1" "$c2"; do
    if [ -f "$f" ]; then
      if ! grep -q "from azext_connectedk8s.azure.mgmt.core.tools import get_arm_endpoints" "$f"; then
        backup "$f"
        sed -i "s|from azure.mgmt.core.tools import get_arm_endpoints|from azext_connectedk8s.azure.mgmt.core.tools import get_arm_endpoints|g" "$f"
        echo "patched $f"
      fi
    fi
  done
}

patch_init_py
patch_custom_py
create_shim
patch_clients

echo "connectedk8s extension patched (idempotent)"
