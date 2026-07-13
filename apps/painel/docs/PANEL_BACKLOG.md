# Painel — Backlog (o que falta)

Registo do que ficou **deferido** durante a varredura "painel honesto + UX"
(Junho 2026). Estas peças foram removidas/ocultadas do UI por ainda não terem
suporte no backend — não são bugs, são funcionalidades por construir. Quando
forem implementadas, voltar a expô-las no painel.

## Partner › Definições

A página de definições do partner foi reduzida às secções que **persistem mesmo**
(Empresa e Contactos, via `updateProfile`). Removidas até haver backend:

- **Equipa** — convidar/remover membros (`partner_staff`).
  - Falta: callable `invitePartnerStaff(email, name)` que cria o utilizador
    `type: partner_staff` sob o partner e devolve um reset link (espelhar
    `createPartnerWithOwner` em `functions/src/painel.ts`).
  - Lista real em `/partners/{id}/staff` + leitura no repo partner.
- **Pagamentos** — método de payout (M-Pesa/IBAN).
  - Falta: persistir em `/partners/{id}/payout` (`updateProfile` ou novo método)
    + regras de escrita (partner_owner).
- **Notificações** — preferências por canal (email/SMS).
  - Falta: persistir em `/partners/{id}/notificationPrefs` e respeitá-las no envio
    (ligado ao broadcast/FCM da Fase D7).
- **Segurança** — alterar password / 2FA / sessões.
  - Password e 2FA: usar o fluxo do Firebase Auth (não há UI real ainda).
  - **Sessões por dispositivo não são suportadas pelo Firebase Auth.** Só é
    possível "revogar todas" via `revokeUserSessions(uid)` (callable admin já
    existe) — expor no partner se desejado.

## Métricas sem fonte de dados

Cartões/gráficos removidos por não terem dados reais. Exigem novos agregados ou
campos antes de voltarem:

- **Taxa de aceitação** e **tempo até aceite** (partner performance) — precisam de
  timestamps de oferta/aceite no `trip` (ex.: `offeredAt`, `acceptedAt`).
- **SLA** e **tempo médio de resposta** (support) — precisam de timestamps de
  primeira resposta nos tickets.
- **Séries históricas de 12 meses** (rating, aceitação) — precisam de um nó de
  agregação (ex.: `/metrics/{...}` escrito por uma function agendada).
- **Donut de categorias resolvidas** (support) — precisa de `category` nos tickets.

## Detalhes admin

- **Manutenção de veículos (admin)** — a aba foi removida do detalhe do veículo.
  Os dados existem em `/partners/{pid}/vehicles/{vid}/maintenances` (lidos pelo
  repo partner); falta um método de leitura no `FirebaseAdminDataRepository` e
  re-adicionar a aba.

## Notas

- O preço/comissão do painel já lê de `/config/pricing` (fonte única); as taxas
  por tipo de viagem vêm de `fares[*].commission`.
- O upload de foto de veículo para o Storage continua por fazer (o diálogo
  "Adicionar veículo" aceita um URL colado em `photoUrl`).
