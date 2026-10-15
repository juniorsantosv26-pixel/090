# AFTERFALL 0.3.1 — Compilação Android de teste

**Importante:** Esta pasta contém código-fonte do jogo e um processo de compilação automático. Um arquivo ZIP contendo arquivos Godot NÃO instala no Android. Somente o `.apk` gerado pelo exportador e assinado é instalável.

## Android: caminho mais curto

1. Instalar o **Godot Editor para Android** da fonte oficial e baixar seus modelos de exportação (export templates) compatíveis.
2. Extrair este ZIP em uma pasta acessível ao editor; importar `project.godot`.
3. Em **Projeto > Exportar**, escolher o preset **Android** e usar **Exportar Projeto** para gerar `AFTERFALL-0.3.1-debug.apk`.
4. O APK gerado poderá ser instalado pelo gerenciador de arquivos do aparelho, autorizando a instalação dessa fonte no Android.

O Godot com os modelos de APK pré-compilados não exige configurar o ambiente Gradle/GABE. GABE é útil para projetos que escolhem a opção de compilação Gradle personalizada. Esta build usa `gradle_build/use_gradle_build=false`.

## GitHub Actions: compilar no servidor

O arquivo `.github/workflows/android-apk.yml` configura uma compilação de teste automatizada usando **Godot 4.5.2**, SDK Android e uma chave de depuração temporária. Colocar todo o conteúdo desta pasta na raiz de um repositório GitHub que permite GitHub Actions. A execução será iniciada por push nas branches `main` ou `afterfall-android-build`, ou pelo botão **Run workflow**.

A execução primeiro importa a cena e roda `tests/runtime_smoke.gd`. Somente se passar, executa `--export-debug Android build/AFTERFALL-0.3.1-debug.apk`. O artefato `AFTERFALL-0.3.1-APK-Android-arm64` contém um **ZIP com o APK dentro**, além dos logs da compilação. O APK é de depuração e deve ser usado apenas para testes locais.

## Compatibilidade e limites

- Android ARM64 (arquitetura `arm64-v8a`), modo horizontal.
- Renderizador **OpenGL Compatibility** para melhorar compatibilidade com GPU móvel.
- Jogo offline, sem permissão de internet.
- Ainda é uma fundação de gameplay e visuais procedurais. Modelos humanos detalhados, rigs avançados e animações capturadas por movimento não estão presentes.
- O ZIP entregue aqui foi testado apenas estaticamente. Nenhum APK foi compilado, executado ou testado no Infinix Note 50x 5G neste ambiente.

### Sobre o GitHub

A conexão GitHub permitiu leitura da lista de repositórios, mas uma tentativa de criar a branch `afterfall-android-build` em `juniorsantosv26-pixel/zerox.01` falhou com **HTTP 403 (Resource not accessible by integration)**. Nenhuma alteração foi aplicada nesses repositórios. A conexão precisa obter escrita de conteúdo no repositório que receberá o projeto antes que eu possa publicar/acionar o build por esse canal.
