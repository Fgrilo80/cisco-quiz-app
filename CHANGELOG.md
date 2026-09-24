# Changelog — Cisco Quiz (Flutter)

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
