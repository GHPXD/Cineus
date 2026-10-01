# Cineus — Monetização e configuração de produção

## Princípio do produto

O Cineus continua jogável por completo sem pagamento.

- Daily Dicas e Poster: gratuitos.
- Estágios: gratuitos; tickets regulam ritmo, não compram acesso ao catálogo.
- Desafios entre amigos, conquistas e catálogo: gratuitos.
- Rewarded ads: sempre opcionais.
- Cineus Pass: conveniência/premium; nunca desbloqueia gameplay essencial.

Essas invariantes vivem em `MonetizationPolicy`.

## Rewarded ads

Baseline implementada:

- recompensa: **+2 tickets**;
- limite: **3 recompensas por dia UTC**;
- o saldo só é creditado depois que `MonetizationService.showRewarded()`
  confirma a recompensa;
- falha/cancelamento do anúncio não concede tickets;
- o limite diário é persistido em `app_meta`;
- a superfície some quando o SDK não está disponível ou o limite acabou.

O serviço padrão é `DisabledMonetizationService`, portanto uma build sem
configuração comercial não exibe anúncios falsos/teste.

## Cineus Pass

A camada de domínio não assume se o Pass será compra permanente ou assinatura.
Essa decisão pertence ao produto cadastrado na App Store / Google Play.

O estado suporta:

- disponibilidade da loja;
- preço localizado fornecido pela loja;
- entitlement ativo;
- compra;
- restauração.

Com Pass ativo, anúncios **não opcionais** devem ser suprimidos. Rewarded ads
continuam sendo uma escolha voluntária do jogador se o produto decidir mantê-los.

## Integração real de lojas/ads

Antes de substituir `DisabledMonetizationService` por um adaptador real:

1. criar os produtos do Pass no App Store Connect e Google Play Console;
2. definir se o Pass é non-consumable ou subscription;
3. criar os ad-unit IDs de produção para rewarded;
4. adicionar os SDKs oficiais escolhidos e regenerar `pubspec.lock`;
5. no Android, adicionar `INTERNET` somente quando a build realmente usar ads;
6. configurar consentimento/privacidade exigidos pelos SDKs e mercados atendidos;
7. validar compra, restauração e recompensa em TestFlight/Internal Testing;
8. atualizar Privacy Policy, App Privacy e Google Play Data Safety;
9. nunca confiar em um boolean local como autoridade de entitlement pago.

IDs de anúncio, product IDs, chaves e credenciais **não devem ser hardcoded** no
repositório. O adapter deve recebê-los por configuração de release.

## Telemetria

Os eventos de produto já estão instrumentados através de `ProductTelemetry`:

- `daily_opened`;
- `game_completed`;
- `extra_hint_bought`;
- `rewarded_completed`;
- `pass_purchase_started`;
- `pass_entitlement_active`;
- `pass_restore_started`.

A implementação padrão é `DisabledProductTelemetry`: nada é coletado ou
transmitido. Conectar um provedor real exige atualizar as declarações de
privacidade antes da release correspondente.

## Economia

A economia atual permanece deliberadamente generosa porque o objetivo não é
forçar compra de tickets. Rewarded é um bônus de conveniência.

Qualquer rebalanceamento futuro deve ser orientado por retenção e uso real
(D1/D7, conclusão de Daily/Stage, saldo médio de tickets e taxa de rewarded),
não por criar escassez artificial.
