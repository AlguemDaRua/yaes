# Changelog

## [1.0.0+2] - 2026-07-12

### Added
- Carteira de comissão da YA Direct também credita corridas digitais (M-Pesa/e-Mola) como ganho, não só debita corridas em cash.
- Fluxo real de avaliações: passageiro avalia o motorista no fim da viagem, motorista vê o feed real de avaliações.
- Motorista respeita o opt-out de notificações da frota (config do partner no painel).

### Changed
- Splash único (~2s, era ~10-12s).
- `flutter analyze` limpo (291 → 0 avisos); exclui `functions/node_modules/**` da análise.

### Verified
- `flutter analyze --no-pub` = 0 issues
- `flutter test` = 85 testes
- `functions`: `npm test` = 150 testes, `npm run lint` limpo

## [1.0.0+1] - rc1

Estado inicial: app sem dados fictícios, categorias Moto/Txopela/Económico em produção, signing de release commitado.
