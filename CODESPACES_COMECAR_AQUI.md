# AFTERFALL 0.3.1 — Codespaces para APK

**Objetivo:** publicar o projeto Godot 3D no repositório `juniorsantosv26-pixel/090` e iniciar um workflow de compilação na nuvem. Este ZIP **não é** um APK.

## Uma única execução no terminal do seu Codespace

1. Abra o seu Codespace (repositório `090`).
2. Arraste o arquivo `AFTERFALL-Codespaces-0.3.1-Compilar-APK.zip` para a **raiz do repositório**, no explorador de arquivos do VS Code.
3. Abra **Terminal > New Terminal** e execute:

```bash
unzip -oq AFTERFALL-Codespaces-0.3.1-Compilar-APK.zip -d . && bash INSTALL_CODESPACES.sh
```

4. Acompanhe: https://github.com/juniorsantosv26-pixel/090/actions/workflows/android-apk.yml
5. Se a execução terminar **verde**, abra a execução, baixe **AFTERFALL-0.3.1-APK-Android-arm64** e extraia o arquivo `AFTERFALL-0.3.1-debug.apk` para instalar no Android.

## Cuidados

- Se o terminal disser `403`, o Codespace não tem autorização para push. O script não consegue contornar isso.
- Se a execução do Actions falhar, abra a etapa vermelha e copie o erro. Não instale um APK de uma compilação falha.
- A build utiliza uma **chave de depuração temporária**. APKs de diferentes execuções podem exigir desinstalar a versão antiga, com perda do save local; não use como assinatura de produção.
- O jogo 3D ainda utiliza modelos e materiais procedurais. **Não é uma edição final com gráficos cinematográficos**.
- Nenhum APK foi compilado ou instalado nesta preparação; o relatório de testes confirma apenas integridade e código estático.
