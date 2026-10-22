# Cineus Commerce — direitos, conteúdo e ciclos

API comercial, Python 3.12, FastAPI e SQLite. Implementada e testada localmente; **não publicada e sem credenciais de lojas ou anúncios**. Não existe endpoint de compra fictícia ou concessão administrativa pública. Checkout nativo, SDK de anúncios, conteúdo assinado e ciclos do Clube estão implementados. Configuração/ativação e limitações estão em [OPERACAO-COMERCIAL.md](OPERACAO-COMERCIAL.md).

## Execução local no Windows

Na pasta `C:\Projects\Cineus\backend`:

```powershell
py -3.12 -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements-dev.txt
.\.venv\Scripts\python.exe -m cineus_commerce init-local --out .secrets/local.json
.\.venv\Scripts\python.exe -m cineus_commerce --config .secrets/local.json serve --port 8000
```

`init-local` cria chaves aleatórias separadas e recusa sobrescrever configuração existente. A configuração fica somente no servidor, ignorada pelo Git. Ela não ativa provedores. O HTTP em loopback serve aos testes da API; o app exige HTTPS. Não exponha essa porta diretamente na internet.

Em outro terminal, com a mesma configuração:

```powershell
.\.venv\Scripts\python.exe -m cineus_commerce --config .secrets/local.json worker
.\.venv\Scripts\python.exe -m cineus_commerce --config .secrets/local.json check
.\.venv\Scripts\python.exe -m cineus_commerce --config .secrets/local.json public-key
.\.venv\Scripts\python.exe -m cineus_commerce --config .secrets/local.json backup --out var/backup-NOVO.sqlite
```

`public-key` imprime exclusivamente a chave pública Ed25519. Nunca copie o JSON secreto para o app. `worker` tenta novamente eventos, verificações pendentes e acknowledgements de compras. Sem ele a reconciliação contínua fica incompleta. O processo pode ser encerrado com Ctrl+C.

Testes:

```powershell
New-Item -ItemType Directory -Force .pytest-work
.\.venv\Scripts\python.exe -m pytest -c pytest.ini tests --basetemp=.pytest-work/local-test
```

O diretório passado ao pytest é temporário, exclusivo e interno ao projeto; o pytest pode apagá-lo. Em Linux/CI basta omitir `--basetemp`. `requirements.txt` fixa dependências de execução; `requirements-dev.txt` acrescenta testes. `requirements.in` registra as dependências diretas. Atualizações exigem revisão, novo lock e regressão.

## Configuração por ambiente

Use `config.example.json` como lista de campos, substituindo os placeholders. Eles são inválidos propositalmente. É possível fornecer as mesmas variáveis pelo ambiente em vez de JSON.

| Campo | Uso |
| --- | --- |
| `CINEUS_ENV` | `development`, `sandbox` ou `production`; explícito no servidor |
| `COMMERCE_DATABASE` | Caminho absoluto do banco persistente, separado por ambiente |
| `COMMERCE_SIGNING_KEY` | Seed privada Ed25519, 32 bytes em base64 |
| `COMMERCE_ENCRYPTION_KEY` | Chave independente AES-256-GCM, 32 bytes em base64 |
| `COMMERCE_HASH_KEY` | Chave independente HMAC, 32 bytes em base64 |
| `COMMERCE_KEY_ID` | Identificador da chave de assinatura; padrão `v1` |
| `GOOGLE_PRODUCTS`, `APPLE_PRODUCTS` | JSON de ID **real da loja → ID interno**; vazio desativa ofertas reconhecidas |
| `GOOGLE_APPLICATION_CREDENTIALS` | Arquivo de service account com acesso restrito à Play Developer API |
| `GOOGLE_PUSH_AUDIENCE`, `GOOGLE_PUSH_EMAIL`, `GOOGLE_PUBSUB_SUBSCRIPTION` | Destino, identidade e assinatura Pub/Sub exatos autorizados para RTDN |
| `APPLE_KEY_PATH`, `APPLE_KEY_ID`, `APPLE_ISSUER_ID` | Credencial da App Store Server API, arquivo montado fora da imagem |
| `APPLE_APP_ID` | Apple ID numérico obrigatório para produção |
| `APPLE_ROOT_CERTIFICATES` | Caminhos separados por vírgula dos certificados raiz Apple oficiais |
| `ADMOB_SSV_UNITS` | Allowlist de ad units separadas por vírgula; vazia desliga recompensas |

`GOOGLE_PACKAGE` e `APPLE_BUNDLE_ID` devem corresponder ao app instalado (`dev.cineus.cineus` atualmente). São validados junto ao ambiente. O banco registra ambiente, identificadores do app e fingerprints das chaves de criptografia/HMAC; recusa abertura com configuração incompatível. Sandbox e produção exigem bancos, credenciais e chaves separados.

Produtos permanentes reconhecidos:

- `cineus.collection.premiere.v1`: os seis IDs exatos da Coleção Estreia da Sprint 3.
- `cineus.plus.permanent.v1`: remoção permanente de interrupções e dois itens próprios.

`cineus.collection.night.v1` e `cineus.collection.city.v1` concedem seis itens cada. `cineus.club.monthly.v1` usa calendário explícito, plano mensal e ciclos únicos; cosméticos de ciclos válidos permanecem após a assinatura. Configurar Clube requer duas coleções distintas preparadas. Não se concede item por informar seu ID ou enviar `verified: true`. Cadastro nas lojas e provas genuínas ainda são pendências externas.

Os consumíveis `cineus.tickets.20.v1` e `cineus.tickets.60.v1` usam saldo comprado separado, sem expiração diária, e operações remotas idempotentes de reserva, confirmação e estorno. Exigem produtos reais mapeados e provas das lojas; restauração do progresso local não concede esse saldo. `/v1/growth` acrescenta bootstrap de tempo/configuração, telemetria consentida, backup criptografado e convites privados. Consulte [ativação das cinco sprints](../docs/business/audit-2026-10-19/ATIVACAO.md) para configuração, limites e testes nativos pendentes.

## Ativação futura no Flutter

Após publicar e validar um endpoint HTTPS, a build recebe somente configuração pública:

```text
--dart-define=CINEUS_ENV=sandbox
--dart-define=CINEUS_COMMERCE_URL=https://SEU-DOMINIO
--dart-define=CINEUS_COMMERCE_PUBLIC_KEY=CHAVE_PUBLICA_BASE64
--dart-define=CINEUS_COMMERCE_KEY_ID=v1
```

A URL deve ser uma origem HTTPS sem usuário, query ou subcaminho. Flutter rejeita redirecionamentos. Chave e ambiente devem coincidir com o servidor. Sem URL/chave válidas o backend fica desligado, sem HTTP nem criação de identidade comercial. O adaptador também fica desligado no web. Flags de produto não substituem prova de compra nem oferecem preços.

Android guarda a credencial comercial em armazenamento protegido e exclui seus arquivos do backup. iOS usa Keychain do próprio aplicativo. O servidor recebe apenas hashes dos segredos aleatórios; eles não são senhas humanas. Não há cadastro obrigatório para jogar. A restauração nativa preserva vínculo de titular e requer o acesso comercial; uma chave privada opcional recupera a identidade quando o sistema não a retém. **Não há recuperação por nome de exibição ou promessa de sincronização entre Android/iOS**.

## Protocolo e limites

Veja [PROTOCOLO.md](PROTOCOLO.md) e [OPERACAO.md](OPERACAO.md). O servidor guarda compras por origem e recibos únicos; o app revalida snapshots assinados e aplica posse por origem em transação SQLite. Falha de rede mantém o último estado confiável. Revogação confirmada remove apenas sua origem e repara equipamento que deixou de ser válido.

Recompensa confirmada vale +2 tickets, até três por dia UTC por identidade comercial. O recibo é creditado uma vez na mesma transação do saldo e depois confirmado ao servidor. Duplicação, reinício e resposta perdida não repetem o crédito na mesma instalação. Isso não torna o saldo inteiro do jogo um ledger remoto, nem prova que identidades diferentes representam pessoas diferentes.

Para impedir crédito duplo entre aparelhos, um recibo entregue fica vinculado à instalação que o recebeu. Se ela for perdida no intervalo entre recebimento e confirmação, a transferência automática é bloqueada; exige reconciliação de suporte. Não liberar um segundo crédito por suposição. Sem aparelho/credencial recuperáveis, não há garantia de restaurar tickets locais.

## Verificação com provedores

- Google: consulta `purchases.productsv2`, confere estado, produto, quantidade, pacote, ambiente e `obfuscatedExternalAccountId`; concede em transação antes de tentar acknowledgment. RTDN autenticada serve de gatilho para consultar o estado atual, conforme a [referência oficial de notificações](https://developer.android.com/google/play/billing/rtdn-reference). JWT do push tem audiência, emissor, e-mail verificado e assinatura Pub/Sub conferidos conforme [push autenticado](https://docs.cloud.google.com/pubsub/docs/authenticate-push-subscriptions).
- Apple: SDK oficial `app-store-server-library`, `SignedDataVerifier` com validação online, raízes oficiais, bundle e ambiente. A notificação assinada não substitui consultar a transação atual. Tipo, propriedade, quantidade, `appAccountToken` e revogação são conferidos. Ver [SDK oficial](https://github.com/apple/app-store-server-library-python).
- AdMob: ECDSA sobre a query original, chave obtida somente no endpoint oficial, ad unit/valor/moeda técnica/identidade/nonce conferidos. O nonce é criado antes de mostrar o anúncio. Ver [Server-side verification](https://developers.google.com/admob/android/ssv).

Os testes usam respostas de lojas e OIDC controladas, chaves efêmeras e assinaturas criptográficas reais locais. **Eles não substituem compras em Internal Testing/TestFlight nem callbacks genuínos dos provedores.**

## Estado operacional e custo

Não foi contratado servidor, domínio, backup ou serviço pago. A execução local usa os recursos do computador. O Compose é uma proposta revisável de **uma instância**, API + worker, com limites de 256 MiB por processo, disco persistente compartilhado e porta somente em loopback. Não foi executado nem medido em hospedagem.

Antes de contratar: obter orçamento de computação, disco/IO, HTTPS/domínio, backup externo, tráfego e monitoramento; conferir custo total em reais e limites. Os limites do Compose não são dimensionamento comprovado e não incluem SO/proxy/backup. Escolher provedor e gasto depende dessa revisão. SQLite não deve ser compartilhado por múltiplas máquinas; crescimento exige migração planejada. Nenhum custo futuro está presumido como zero.
