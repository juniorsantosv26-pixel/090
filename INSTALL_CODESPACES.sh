#!/usr/bin/env bash
set -euo pipefail

# Execução controlada pelo usuário dentro de seu GitHub Codespace.
# Nunca execute este script em seus repositórios de IA ZeroX.
REPO_REQUIRED="juniorsantosv26-pixel/090"
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "$ROOT" ]]; then
  echo "ERRO: execute no terminal do repositório 090 (não é um repositório Git)." >&2; exit 2
fi
cd "$ROOT"
ORIGIN="$(git remote get-url origin 2>/dev/null || true)"
if [[ ! "$ORIGIN" =~ (^|[:/])juniorsantosv26-pixel/090(\.git)?$ ]]; then
  echo "ERRO: repositório remoto inesperado: $ORIGIN" >&2
  echo "Esperado: github.com/juniorsantosv26-pixel/090" >&2; exit 2
fi
BRANCH="$(git branch --show-current)"
if [[ "$BRANCH" != "main" ]]; then
  echo "ERRO: branch atual '$BRANCH'; esperado: main." >&2; exit 2
fi
for file in project.godot export_presets.cfg .github/workflows/android-apk.yml scripts/world.gd scenes/main.tscn; do
  if [[ ! -s "$file" ]]; then echo "ERRO: arquivo ausente: $file" >&2; exit 2; fi
done
if ! git diff --cached --quiet; then
  echo "ERRO: já há mudanças staged no repositório. Finalize-as antes de iniciar o instalador." >&2; exit 2
fi
python3 tests/build_preflight.py
# Sintaxe básica do instalador antes de publicação.
bash -n INSTALL_CODESPACES.sh
if [[ "${AFTERFALL_DRY_RUN:-0}" == "1" ]]; then
  echo 'DRY RUN: verificações estáticas aprovadas; nada foi publicado.'
  exit 0
fi
# Apenas arquivos AFTERFALL são versionados. README e LICENSE originais ficam intactos.
git add .gitignore project.godot export_presets.cfg README_AFTERFALL.md README_APK.md CODESPACES_COMECAR_AQUI.md INSTALL_CODESPACES.sh scenes scripts assets tests tools docs .github/workflows/android-apk.yml
if git diff --cached --quiet; then
  echo "Arquivos AFTERFALL já estavam versionados. Acione manualmente GitHub Actions se necessário."
else
  git commit -m "AFTERFALL 0.3.1: game source and ARM64 Android APK CI"
  git push origin HEAD:main
fi
printf '\nPronto: publicação Git concluída.
'
printf 'Abra: https://github.com/%s/actions/workflows/android-apk.yml\n' "$REPO_REQUIRED"
printf 'Espere a execução ficar verde para baixar o artifact APK.
'
