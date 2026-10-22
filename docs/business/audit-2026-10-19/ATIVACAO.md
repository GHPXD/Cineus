# Ativação e operação das cinco sprints

Implementação local em 19/10/2026. A galeria está em `docs/preview/growth-2026-10-19/GALERIA.html`. Os recursos locais funcionam sem servidor; os serviços remotos mostram indisponibilidade enquanto não houver configuração válida.

## Caminhos no aplicativo

| Recurso | Caminho |
| --- | --- |
| Continuar / próxima meta | Início, abaixo do carrossel |
| Missões e recompensas | `/journey` |
| Arquivo dos três modos | `/archive` |
| Domínio por tema e revisão | `/mastery` |
| Estatísticas e filtros | `/stats` |
| Consentimento, backup e recuperação | Configurações → Dados, `/data` |
| Desafios privados | `/friends` |
| Packs de tickets | Carteira / ofertas, após configuração válida da loja |

## Backend e privacidade

Seguir `backend/README.md`, `backend/OPERACAO.md` e `backend/PROTOCOLO.md` para chaves, HTTPS, API, worker e backup persistente. Não colocar segredos no Flutter. `/v1/growth` usa a identidade comercial existente; a resposta assinada vincula ambiente, conta, instalação, ação e nonce aleatório. Eventos, backup e convites não são endpoints públicos de escrita sem autenticação.

O bootstrap oferece hora autenticada e parâmetros limitados. A âncora de tempo dura até 24 horas na execução; com backend configurado, nova renovação de tickets exige âncora válida. A build sem backend preserva o jogo local e não trata o relógio do aparelho como prova comercial.

A telemetria exige consentimento explícito, limita a fila a 2.000 registros e 60 dias e envia lotes de até 50 eventos. Não inclui palpites, nomes de cartão ou recibos. Backup é uma ação separada: contém progresso necessário à restauração, é criptografado em repouso no servidor e pode ser excluído. A revisão editorial continua manual; o envio não altera automaticamente os catálogos.

Relatório agregado, após existir uma base real consentida:

```powershell
cd backend
.\.venv\Scripts\python.exe -m cineus_commerce.metrics_report --database C:\CAMINHO\commerce.sqlite
```

O arquivo é aberto somente para leitura. DAU/MAU referem-se às contas consentidas; D1/D7/D30 usam primeira atividade observada dentro da retenção disponível. Valores do SDK são estimativas não reconciliadas, separados por moeda. Não equivalem a faturamento recebido.

## AdMob e lojas

1. Configurar app IDs nativos, unidades recompensada/intersticial/banner de cada plataforma, público real e consentimento. Usar unidades oficiais de teste no sandbox. A build exige `CINEUS_ADS_REVIEWED` e `CINEUS_ADMOB_NATIVE_CONFIGURED`, além das flags de produto e unidades válidas.
2. Ativar `CINEUS_REWARDED`, `CINEUS_INTERSTITIALS` e/ou `CINEUS_BANNERS` apenas nos ambientes preparados. Unidades ficam em `CINEUS_ADMOB_ANDROID_REWARDED`, `CINEUS_ADMOB_ANDROID_INTERSTITIAL`, `CINEUS_ADMOB_ANDROID_BANNER` e equivalentes `IOS`. O público usa `CINEUS_ADS_AUDIENCE`. Flags não substituem UMP, direitos ou disponibilidade.
3. Configurar endpoint SSV real e allowlist no servidor. Callback do SDK não concede tickets sozinho. Confirmar anúncio completo, cancelado, sem preenchimento, pendência, reinício e callback duplicado em aparelhos reais.
4. Cadastrar produtos **consumíveis** reais mapeados aos IDs internos `cineus.tickets.20.v1` e `cineus.tickets.60.v1`, habilitar `CINEUS_TICKET_PACKS` e conferir credenciais/notificações oficiais. Preço vem da loja; não há preço fabricado. Saldo comprado não expira com os tickets diários.
5. Validar compra pendente, duplicação de callback, consumo, reinstalação/recuperação, revogação e reembolso em Play Internal Testing e TestFlight. Windows e mocks não substituem esses testes. Saldo comprado exige conexão ao ser utilizado; bônus locais não são transferidos pelo backup.

Sem configuração, as áreas comerciais continuam em placeholder. Não habilitar produção apenas para fazer desaparecer esse estado.

## Experimentos

`CINEUS_ECONOMY_ROLLOUT_PERCENT` no servidor aceita percentual de 0 a 100, padrão **0**. A distribuição determinística usa a conta. Controle mantém bônus dez; tratamento usa quatro em estágios ainda sem contrato e adiciona título visual. Contratos existentes permanecem, inclusive depois de desligar o rollout. Dez tickets diários não foram reduzidos nesta entrega. O bootstrap também mantém um grupo de controle de banner.

Anotar hipótese, período, elegibilidade, receita por conta, D7, abandono por saldo, falhas e decisão antes de ampliar. Uma variante implementada não prova ganho de mercado. Não há limites de vídeo ou preços arbitrariamente alterados em produção.

## Convites e publicação

Publicar `hosting/invites/` somente após definir domínio e URLs reais de loja. Seguir seu README para associações Android/iOS e cabeçalhos. `CINEUS_PUBLIC_BASE_URL` alimenta o host Android automaticamente; no iOS configurar o entitlement opcional e a associação no Xcode. Sem domínio, continuam o código e `cineus://`.

Confrontos são privados, um anfitrião e um convidado, sete dias de validade, sem chat, ranking público ou premiação. Resultado é informado pelo cliente e identifica ajuda; isso não é um protocolo antitrapaça competitivo. Compartilhamento exige ação do jogador.

`docs/legal/content-rights.json` é inventário de evidências, não autorização dos titulares. `scripts/validate_content_rights.py --public-release` bloqueia a preparação pública enquanto grupos comerciais estiverem sem comprovação. Resolver público, direitos, termos, formulários das lojas e testes nativos antes de ativar receita real.
