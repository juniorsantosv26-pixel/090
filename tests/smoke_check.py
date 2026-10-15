"""Alias maintained for legacy QA: checks Android export readiness; no engine available."""
from pathlib import Path
import subprocess, sys
here = Path(__file__).resolve().parent
raise SystemExit(subprocess.call([sys.executable,str(here/'build_preflight.py')]))
