# AFTERFALL — Ecos da Extinção — 0.3 Android Build Source

Jogo 3D original de sobrevivência apocalíptica para Android, em formato horizontal, completamente offline. Esta versão mantém a base procedural 0.2 (personagem, terreno, ruínas, vegetação, infectados, controles, missão Frequência 17, chuva e progressão local) e adiciona configuração de exportação de **APK ARM64** e um pipeline de GitHub Actions.

**Atenção: este ZIP é o projeto compilável, não um APK.** Para gerar o instalador, seguir `README_APK.md`. O artefato produzido pelo pipeline será um ZIP que **contém o APK instalável**, não código-fonte.

- `project.godot`: configurações gerais do jogo.
- `scenes/main.tscn`: cena principal.
- `scripts/`: lógica de gameplay e geração do mundo.
- `assets/`: texturas procedurais e ícones autorais.
- `export_presets.cfg`: Android ARM64, APK, sem Gradle, sem internet.
- `.github/workflows/android-apk.yml`: importação, smoke de Godot, exportação e upload do APK.
- `tests/build_preflight.py`: verificação estática (não substitui teste real do Godot).

Nenhum recurso extraído do Last Day on Earth é redistribuído aqui. Texturas, geometrias e código foram criados para este projeto.
