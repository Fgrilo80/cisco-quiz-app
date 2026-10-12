# Changelog — Cisco Quiz (Flutter)

## 1.2.11+13 — 2026-10-12

- O APK arm64 de release passa a ser assinado com uma chave de release estável (`CN=Cisco Quiz`, alias `ciscoquiz`). O keystore não entra no repositório; o GitHub Actions lê os segredos `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_PASSWORD` e `ANDROID_KEY_ALIAS`.
- Certificado SHA-256: `45:3D:1D:C9:48:6E:76:F4:F5:2B:C5:16:B5:10:5A:9F:AF:D8:DF:87:CF:EC:F1:25:DC:A4:E4:54:5B:F0:E6:D8`.
- Esta é a última versão que obriga a desinstalar a anterior: a chave muda da debug (uma diferente em cada máquina de build) para esta chave de release. A partir daqui, a versão seguinte instala por cima.
- `versionName` 1.2.11. O APK arm64 em split-per-abi fica com `versionCode` 2013 (13 + offset 2000). O banco continua com 1230 perguntas.

## 1.2.10+12 — 2026-09-24

- A base online atualiza por **SHA-256** do corpo descarregado. A mesma contagem (1230) com texto diferente — como a reescrita length-bias — marca «nova base» e aplica-se sozinha no arranque.
- No Windows, descarregar a app abre o zip (`windowsUrl`), com fallback para a página de releases. Android e iOS continuam no APK (`apkUrl`). A comparação de versão continua a ser o `versionName`.
- O APK arm64 de release continua assinado com a chave de **debug** (não há keystore de release no repositório).

## 1.2.9+11 — 2026-09-24

- Banco sincronizado com Cricket `main` `02c0a868` (pós length-bias): mesmas **1230** perguntas; distratores reescritos para o comprimento não indicar a resposta certa.
- Contagens inalteradas: clássicos **1190** (CCST 196, CCNA 202, CCNP 197 × PT/EN) + **Cybersegurança** 20×2.

## 1.2.8+10 — 2026-09-23

- Banco sincronizado com Cricket **v3.2.1**: clássicos **1190** (CCST 196, CCNA 202, CCNP 197 × PT/EN) + **Cybersegurança** 20×2.
- Contagens e testes atualizados (total **1230**). Trilho `cyber` mantido.

## 1.2.7+9 — 2026-09-21

- Banco sincronizado com Cricket **v3.2**: 1184 (CCST/CCNA/CCNP) + 24 starters **Cybersegurança** (`cyber`).
- UI: 4.º cartão Cybersegurança / Cybersecurity; parser e filtros incluem o novo trilho.
- Contagens e testes atualizados (total 1208).

## 1.2.6+8

- Banco 1100; auto bank refresh + app version check.
