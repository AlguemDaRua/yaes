# Changelog

## [0.1.0+2] - 2026-07-12

### Added
- Partner › Equipa: convidar membros da equipa (`invitePartnerStaff`), lista real de `partners/{id}/staff`.
- Partner › Pagamentos: método de payout (M-Pesa/IBAN) persistido.
- Partner › Notificações: opt-out de broadcast para a frota.
- Upload real de foto de veículo (Storage).
- Payout schedule real: admin define o dia da semana, Ganhos do partner mostra a data verdadeira do próximo payout.
- Extracto da carteira mostra o tipo `earning` (payout digital).

### Verified
- `flutter analyze --no-pub` = 0 issues
- `flutter test` = 90 testes

## [1.0.0] - 2026-05-09

### Added
- Admin panel com páginas para partners, drivers, veículos, corridas, users, finanças, comissões, relatórios, documentos, alertas, auditoria, preços, notificações, settings e mapa live.
- Partner panel com frota, corridas, ganhos, performance, incentivos, alertas, documentos, mensagens e settings.
- Support panel com dashboard, fila, tickets, chat, disputas, performance e ações rápidas.
- Auth com email/password, email verification, OTP por telefone e routing por role.
- Integração Firebase RTDB, Auth, Storage e Cloud Functions com flag `USE_FIREBASE`.
- Mapa ao vivo com Mapbox tiles e suporte mock/Firebase/emulators.
- i18n PT/EN com selector nas settings.
- Suite de testes widget/unit/smoke e CI/CD com GitHub Actions + Firebase Hosting.

### Changed
- Páginas async prioritárias usam `AsyncView` para loading, empty e error states.
- `flutter_form_builder` e `form_builder_validators` removidos; `reactive_forms` fica como única library de formulários.
- Error boundary global, Semantics básicos e ordem de foco no login.

### Verified
- `dart analyze --no-fatal-warnings`
- `flutter test` com 86 testes
