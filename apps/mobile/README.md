# Ya (Limousine Executive)

Bem-vindo ao repositório do **Ya**, uma aplicação de mobilidade e transporte executivo (semelhante a plataformas de ridesharing), desenhada para proporcionar uma excelente experiência tanto para Passageiros como para Motoristas.

## 📱 Visão Geral do Projeto

Este projeto é composto por duas partes principais integradas:

1. **Frontend (App Mobile - Flutter):** 
   A aplicação foi desenvolvida em Flutter e atende a dois perfis de utilizador numa única base de código:
   - **Passageiro (`lib/passageiro/`):** Inclui mapa de localização, escolha de destinos, agendamentos, histórico, descontos e gestão de perfil.
   - **Motorista (`lib/motorista/`):** Inclui gestão de corridas ativas, painel de ganhos, avaliações e perfil do motorista.
   - **Autenticação (`lib/authentication/`):** Login e verificação via OTP (número de telemóvel).

2. **Backend (API - Node.js):** 
   Localizado na pasta `backend/`, o servidor fornece as regras de negócio, lidando com utilizadores, corridas, localização e comunicação em tempo real. Estrutura MVC básica com rotas, controladores e modelos.

## 🛠 Principais Tecnologias e Pacotes

- **Linguagem/Framework:** Flutter (Dart), Node.js (JavaScript).
- **Gestão de Estado:** `provider` (`MotoristaState` e `PassageiroState`).
- **Mapas e Localização:** `flutter_map`, `geolocator`, `flutter_polyline_points`, `latlong2`.
- **UI/UX e Responsividade:** `flutter_screenutil`, `google_fonts` (Fonte: Gagalin), animações (`flutter_map_animations`).
- **Outras Funcionalidades:** `flutter_local_notifications` (notificações locais), `image_picker` (fotos), `vibration`, `http` (pedidos backend).

## 📁 Estrutura de Diretórios Principal

- `lib/main.dart`: Ponto de entrada da app, configurações de tema responsivo e registo de rotas (ex: `/login`, `/passanger_initial`, `/driver_initial`).
- `lib/passageiro/`: Lógica, state models e UI específicos do Passageiro.
- `lib/motorista/`: Lógica, state models e UI específicos do Motorista.
- `lib/authentication/`: Telas de login e OTP.
- `lib/services/` e `lib/utilitarios/`: Módulos utilitários e de interacção com a API partilhados, widgets genéricos.
- `backend/`: Código fonte do servidor Node.js (`src/routes`, `src/controllers`, `src/models`).
- `assets/`: Assets estáticos como imagens (carros: `assets/images/cars/`), fontes (`assets/fonts/`) e sons.

---
*Nota: Este ficheiro será continuamente atualizado à medida que novas tarefas forem realizadas e novas funcionalidades implementadas.*
