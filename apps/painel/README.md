# YA Painel

[![CI](https://github.com/SEU_USER/ya_painel/actions/workflows/ci.yml/badge.svg)](https://github.com/SEU_USER/ya_painel/actions/workflows/ci.yml)
[![Deploy](https://github.com/SEU_USER/ya_painel/actions/workflows/deploy.yml/badge.svg)](https://github.com/SEU_USER/ya_painel/actions/workflows/deploy.yml)

Backoffice administrativo da plataforma YA Ride-Hailing (Moçambique).
Painéis: **Admin** · **Partner** · **Support**

## Stack

- Flutter 3.24+ (Web + Desktop)
- Riverpod 3.x (state management)
- GoRouter (routing com role guards)
- Firebase RTDB + Auth + Storage + Cloud Functions
- flutter_map + Mapbox tiles (mapa ao vivo)

## Setup rápido

### 1. Dependências

```bash
flutter pub get
flutter gen-l10n
```

### 2. Modo mock (sem Firebase)

```bash
flutter run -d edge
```

### 3. Firebase + Emuladores

```bash
# Terminal 1 — emuladores
cd ../ya-app && firebase emulators:start

# Terminal 2 — app
flutter run -d edge --dart-define=USE_FIREBASE=true
```

### 4. Firebase produção (ya-app-z)

```bash
flutter run -d edge --dart-define=USE_FIREBASE=true --dart-define=USE_EMULATORS=false
```

## Testes

```bash
flutter test                  # todos
flutter test test/unit/       # unit tests
flutter test --coverage       # com coverage
```

## Deploy

Push para `main`/`master` → GitHub Actions faz build e deploy automático para Firebase Hosting.

## Documentação

- [Arquitetura e funções](docs/architecture-functions.md)
- [Setup Firebase + admin bootstrap](docs/dev-firebase.md)
- [Contribuir](docs/contributing.md)
- [Changelog](CHANGELOG.md)
- [Plano de fases](sections/plano-completar-projecto.md)
