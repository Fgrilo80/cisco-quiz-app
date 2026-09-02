# Cisco Quiz

App nativa (**Android**, **iOS**, **Windows**) para praticar exames **CCST**, **CCNA** e **CCNP**. Interface predefinida em português, com strings em inglês. Nunca usa a marca Cricket na UI.

Site de referência: https://fgrilo80.github.io/cricket/

## O que faz

- Ecrã inicial com cartões **CCST / CCNA / CCNP** e botões **PT** / **EN**.
- Modo **Prática** ou **Exame** (seletor no início):
  - **Prática**: revela certo/errado e a explicação a seguir a cada resposta. Até 50 perguntas, 45 minutos.
  - **Exame**: até 50 perguntas, 45 minutos, **sem** revelar por pergunta — pontuação e revisão completa só no fim.
- **Filtros** de dificuldade (Fácil / Médio / Difícil) e tópico (VLAN, OSPF, Wi-Fi, ACL, NAT, STP, BGP, QoS, …). Se o JSON não tiver `topic`, o tópico deriva de palavras-chave. A app **não inventa** perguntas Cisco; só escolhe da base. Com filtros, o exame usa as que existirem, no máximo 50.
- **Repetir erros** e SRS leve neste dispositivo: falhas ficam devidas já; acertos aumentam o intervalo (1, 3, 7, 14 dias).
- **Estatísticas locais** (sessões e acertos neste aparelho; nada é enviado).
- **Labs CLI**: terminal IOS interativo (não é Packet Tracer nem drag-and-drop). Escreves comandos (`?`, `enable`, `exit`, `show …`) e o dispositivo responde com output enlatado. Cada lab tem uma tarefa e uma verificação.
- **Sem repetir** perguntas até esgotar o conjunto daquela certificação + língua (os IDs vistos ficam neste dispositivo).
- **Pausa** congela o cronómetro e guarda o progresso (prática e exame); podes retomar mais tarde.
- **Filtros** de dificuldade (Fácil/Médio/Difícil · Easy/Medium/Hard) e tópico (VLAN, OSPF, Wi-Fi, …). O tópico vem do JSON se existir; senão é derivado de palavras-chave da pergunta. Exames filtrados têm 50 perguntas ou menos se o conjunto for pequeno; o ecrã mostra quantas restam.
- **Repetir erros** no resultado, e **Rever fracas** no início (SRS local: erros recentes primeiro, intervalos 1/3/7/14 dias quando acertas). Timestamps de erro só neste dispositivo.
- Contagens locais simples: exames feitos, último score por certificação, média das últimas 5.
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
flutter build apk --split-per-abi --release
# saída arm64: build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

Neste Linux o APK arm64 de release fica em `/workspace/Cisco-Quiz.apk` (gerado a partir do split-per-abi).

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
