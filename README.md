# YA — Monorepo

Plataforma de ride-hailing YA (Nampula/Moçambique). Consolidado a partir de
`ya-app` (app mobile) e `ya-painelv1` (painel web), que passam a partilhar o
mesmo backend Firebase.

## Estrutura

```
yaapp/
├── firebase.json          # config única: functions + database + storage + hosting (painel)
├── .firebaserc
├── database.rules.json     # regras do RTDB (única fonte — antes havia cópias divergentes)
├── storage.rules
├── functions/               # Cloud Functions partilhadas por app e painel
├── apps/
│   ├── mobile/               # app Flutter (passageiro + motorista) — ex-ya-app
│   └── painel/                # painel Flutter Web (admin/parceiro/suporte) — ex-ya-painelv1
```

## Porquê consolidar

`functions/`, `database.rules.json` e `storage.rules` já eram partilhados
pelos dois projectos (mesma instância RTDB `ya-app-z-default-rtdb`), mas
viviam em repos separados — mudanças que tocavam nos dois lados (ex.
métricas de aceitação, carteira de comissão) exigiam coordenar dois PRs em
paralelo. Num só repo, essas mudanças passam a ser um único commit.

O painel tinha inclusivamente **duas cópias divergentes** de
`database.rules.json` (uma na raiz do repo antigo, outra em `firebase/`) —
consolidado para uma única fonte de verdade na raiz deste repo.

## Deploy

```
firebase deploy --only functions --project ya-app-z
firebase deploy --only database:prod --project ya-app-z
firebase deploy --only storage --project ya-app-z
firebase deploy --only hosting --project ya-app-z   # requer apps/painel/build/web (flutter build web)
```

## Desenvolvimento

- App mobile: `cd apps/mobile && flutter run`
- Painel web: `cd apps/painel && flutter run -d chrome`
- Functions: `cd functions && npm run build && npm test`

Cada app mantém o seu próprio `pubspec.yaml`/`analysis_options.yaml` — não há
package Dart partilhado entre os dois ainda.

---

Histórico anterior à consolidação: `ya-app` e `ya-painelv1` (repos
separados, mantidos como estavam até esta migração).
