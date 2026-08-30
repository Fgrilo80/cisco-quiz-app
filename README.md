# Cisco Quiz

App nativa (**Android**, **iOS**, **Windows**) para praticar exames **CCST**, **CCNA** e **CCNP**. Interface predefinida em português, com strings em inglês. Nunca usa a marca Cricket na UI.

Site de referência: https://fgrilo80.github.io/cricket/

## O que faz

- Ecrã inicial com cartões **CCST / CCNA / CCNP** e botões de exame **PT** e **EN**.
- Cada exame tira **50 perguntas aleatórias**.
- **Sem repetir** perguntas até esgotar o conjunto daquela certificação + língua (os IDs vistos ficam neste dispositivo).
- **Pausa** congela o cronómetro e guarda o progresso; podes retomar mais tarde.
- Resultado com pontuação e **explicações** por pergunta.
- Bloco **monoespaçado** quando a pergunta traz output de CLI/`show`.
- Cor Cisco **#0a66c2**, opções grandes e fáceis de tocar no telemóvel.
- Cópia offline da base incluída; atualização opcional a partir do GitHub.
- Sem contas, anúncios, analítica ou telemetria.

A app **não inventa perguntas**. A base vem do JSON público:

https://raw.githubusercontent.com/Fgrilo80/cricket/main/cricket.json

Contagens da cópia incluída (por língua): CCST 163 · CCNA 157 · CCNP 160.

## Como correr

Precisas do [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable) no `PATH`.

```bash
cd cisco-quiz-app
flutter pub get
flutter analyze
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

O executável Windows **não se constrói neste Linux**; a pasta `windows/` está incluída. Num PC Windows: `flutter build windows`.

## Estrutura

```
lib/                 código Dart (ecrãs, serviços, modelos)
assets/cricket.json  snapshot offline da base
android/ ios/ windows/  projetos nativos gerados pelo Flutter
```

## Licença

Uso pessoal. As perguntas pertencem à base publicada em https://github.com/Fgrilo80/cricket.
