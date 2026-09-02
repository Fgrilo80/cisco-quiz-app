# Cisco Quiz

App nativa (**Android**, **iOS**, **Windows**) para praticar exames **CCST**, **CCNA** e **CCNP**. Interface predefinida em português, com strings em inglês. Nunca usa a marca Cricket na UI.

Site de referência: https://fgrilo80.github.io/cricket/

## O que faz

- Ecrã inicial com cartões **CCST / CCNA / CCNP** e botões **PT** / **EN**.
- Modo **Prática** ou **Exame** (seletor no início):
  - **Prática**: revela certo/errado e a explicação a seguir a cada resposta. 50 perguntas, 45 minutos.
  - **Exame**: 50 perguntas, 45 minutos, **sem** revelar por pergunta — pontuação e revisão completa só no fim.
- **Labs CLI**: terminal IOS interativo (não é Packet Tracer nem drag-and-drop). Escreves comandos (`?`, `enable`, `exit`, `show …`) e o dispositivo responde com output enlatado. Cada lab tem uma tarefa e uma verificação.
- **Sem repetir** perguntas até esgotar o conjunto daquela certificação + língua (os IDs vistos ficam neste dispositivo).
- **Pausa** congela o cronómetro e guarda o progresso (prática e exame); podes retomar mais tarde.
- Resultado com pontuação e **explicações** por pergunta.
- Bloco **monoespaçado** quando a pergunta traz output de CLI/`show`.
- Cor Cisco **#0a66c2**, opções grandes e fáceis de tocar no telemóvel. Labs usáveis no Windows (teclado) e no telemóvel (scroll + input grande).
- Cópia offline da base incluída; atualização opcional a partir do GitHub.
- Sem contas, anúncios, analítica ou telemetria.

A app **não inventa perguntas**. A base vem do JSON público:

https://raw.githubusercontent.com/Fgrilo80/cricket/main/cricket.json

A cópia incluída tem **986 perguntas**.

## Como correr

Precisas do [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable) no `PATH`.

```bash
cd cisco-quiz-app
flutter pub get
flutter analyze
flutter test
flutter run
```

Dispositivos:

```bash
flutter devices
flutter run -d android          # telemóvel / emulador Android
flutter run -d windows          # só numa máquina Windows
# iOS: macOS + Xcode
```

Organização do pacote: `pt.fgrilo.ciscoquiz` (applicationId `pt.fgrilo.ciscoquiz.cisco_quiz`).

### APK Android

```bash
flutter build apk --release
# saída: build/app/outputs/flutter-apk/app-release.apk
```

Neste Linux foi gerado um APK de release em:

`/workspace/cisco-quiz-app/build/app/outputs/flutter-apk/app-release.apk` (~51 MB)

A pasta `build/` não vai para o Git. Para voltar a gerar: Android SDK 36 + JDK 21 e o comando acima.

O executável Windows **não se constrói neste Linux**; a pasta `windows/` está incluída. Num PC Windows: `flutter build windows --release` (saída típica: `build/windows/x64/runner/Release`).

## Estrutura

```
lib/                 código Dart (ecrãs, serviços, modelos, labs)
lib/labs/            simulador IOS e catálogo de labs
assets/cricket.json  snapshot offline da base
android/ ios/ windows/  projetos nativos gerados pelo Flutter
```

## Licença

Uso pessoal. As perguntas pertencem à base publicada em https://github.com/Fgrilo80/cricket.
