# Protocolo comercial v1

Todos os corpos são JSON limitados a 64 KiB e campos estritos. Erros retornam somente `{"error":"codigo"}`, sem refletir comprovantes ou segredos. Chamadas autenticadas usam `Authorization: Bearer TOKEN_ALEATORIO`; TLS é obrigatório fora de loopback. Não há CORS ou endpoint de concessão livre.

| Rota | Contrato |
| --- | --- |
| `GET /health` | Saúde do processo/banco, sem dados comerciais |
| `POST /v1/identity` | `owner`, `device` UUIDs; `token`, `recovery` aleatórios de 32 bytes em base64url sem padding; devolve snapshot assinado; registro idempotente |
| `POST /v1/identity/recover` | Mesmo corpo; comprova segredo de recuperação, substitui sessão e revoga outras instalações; retentativa com mesmo corpo é idempotente |
| `GET /v1/snapshot` | Snapshot completo dos direitos e recibos pendentes da instalação |
| `POST /v1/purchases/verify` | `platform`: `google`/`apple`; `proof`: purchase token/transaction ID, até 4.096 caracteres; consulta loja, aplica direito e devolve snapshot |
| `POST /v1/reconcile` | Reconsulta origens já conhecidas do titular; não descobre histórico desconhecido da loja |
| `POST /v1/rewards/start` | Cria/reutiliza nonce, retorna `attempt_id`, `expires_at`, `amount: 2`; só com AdMob configurado |
| `POST /v1/rewards/ack` | `receipt_id`; confirma crédito local, idempotente para a instalação autorizada |
| `POST /callbacks/google` | Push Pub/Sub autenticado, assinatura exata autorizada, payload RTDN validado |
| `POST /callbacks/apple` | `signedPayload` JWS verificado; consulta transação atual antes da mudança |
| `GET /callbacks/admob` | Query original assinada; nunca reordenar/decodificar antes da verificação |

`owner` é o identificador a fornecer ao billing nativo como `obfuscatedExternalAccountId`/`appAccountToken`. Não é o nome do perfil local. A prova precisa estar vinculada ao titular; um comprovante de outro titular não é transferido automaticamente. `device` identifica a instalação comercial e deve ser persistido antes do primeiro pedido.

Renovação de sessão após 90 dias: manter owner/device/recovery, gerar token novo, persistir estado de recuperação **antes** do HTTP. Assim o cliente retoma mesmo perdendo a resposta da renovação. Novo dispositivo exige recuperação explícita; não criar uma identidade nova e atribuir compras antigas por coincidência.

## Snapshot

Envelope: `key_id`, `payload` e `signature`. Payload e assinatura em base64url sem padding; Ed25519 assina os **bytes exatos** do JSON UTF-8 do payload, sem recanonização pelo app. A chave pública é fixada pela configuração da build, não recebida do envelope.

Campos do payload:

| Campo | Conteúdo |
| --- | --- |
| `version`, `audience` | `1`, `cineus.commerce.v1` |
| `environment`, `owner`, `device` | Ambiente e destinatários exatos |
| `revision`, `issued_at` | Revisão monotônica do titular e emissão Unix em segundos |
| `grants` | Lista completa: `source`, `product`, `valid_from`, `valid_until`, `revoked`, `items` |
| `rewards` | Recibos ainda não confirmados pela instalação: `id`, `amount: 2`, `occurred_at` |

Cliente rejeita chave, ambiente, destinatário, produto, itens ou assinatura incompatíveis; rede aceita emissão de até dez minutos e tolera cinco minutos futuros. Cache é revalidado criptograficamente; revisão ou emissão anteriores não o substituem. Cosméticos permanentes continuam disponíveis offline. Clube temporário é limitado a 24 horas após o snapshot e à vigência da loja; intersticial exige atualização bem-sucedida. Não é proteção absoluta contra aparelho adulterado, restauração de banco antigo ou relógio manipulado.

`source` é opaco, não contém prova de pagamento. Cada origem comercial pode ser concedida/revogada independentemente. Itens gratuitos e origens ainda válidas sobrevivem à revogação de outra compra. Equipamento inválido recebe a alternativa gratuita existente.

## Falhas e reconciliação

Verificações em voo recebem sequência persistida antes de consultar o provedor. Resposta antiga não desfaz uma revogação mais recente. ID de origem/recibo e ID de notificação são únicos; repetição com conteúdo conflitante é rejeitada. Notificações com mais de 30 dias ou mais de cinco minutos futuros são rejeitadas; a consulta periódica das origens conhecidas recupera estado atual sem depender de replay antigo.

Eventos verificados são persistidos criptografados antes do processamento. Falha intermediária mantém o evento pendente. Polling tenta de novo com backoff entre um minuto e uma hora; sucesso agenda nova consulta após cinco minutos. Trabalho é limitado por lote, com ordenação que evita uma compra falha bloquear todas as outras.

AdMob usa `user_id=owner` e `custom_data=attempt_id`, recompensa de dois `tickets` e ad unit autorizada. Assinatura válida sozinha não libera recompensa de outro titular/nonce. A confirmação aceita atraso de até um dia e exige timestamp dentro da janela do nonce de 30 minutos. O dia do limite é o UTC do evento. O SDK nativo passa os dados; callback do dispositivo apenas inicia consulta, sem conceder saldo.

Antes de pedir ACK ao servidor, o app confirma recibo e movimentação no mesmo commit do saldo. Comprovante já creditado é reconhecido sem somar novamente. O recibo local não é apagado pela limpeza do histórico de diagnóstico. Perda de aparelho após claim e antes de ACK exige suporte; não há transferência automática de recibo ambíguo.

## Segurança de transporte e limites

Limites persistidos: registro/recuperação 10 por 15 minutos por IP de rede observado; geral 180/minuto por IP; autenticado 60/minuto por titular; verificação 10/minuto e reconciliação 3/5 minutos por titular. São valores iniciais, precisam ser ajustados em carga real. IP não é identidade. Cabeçalhos encaminhados arbitrários não são confiados.

CLI desliga access logs, pois URLs SSV contêm dados. Reverse proxy, APM e hospedagem precisam fazer o mesmo para query strings, Authorization e corpos. Não coloque segredos em logs ou tickets públicos. Valores de auditoria são ações, UUIDs técnicos e referências HMAC; as respostas não expõem exceções dos provedores.

## Operações de progresso e crescimento

`POST /v1/growth` exige a mesma autenticação comercial. Corpo estrito: `action`, `nonce` aleatório de 32 bytes em base64url e `payload` específico da ação. A resposta usa o envelope Ed25519, com `version: 1`, `audience: cineus.growth.v1`, ambiente, owner, device, ação, nonce, emissão e `data`. O app compara todos os vínculos; a hora autenticada não depende de acreditar primeiro no relógio do aparelho. Nonce fresco evita aceitar uma resposta antiga no pedido atual.

| Ação | Operação / limite |
| --- | --- |
| `bootstrap` | Hora e configuração limitada; variante de economia determinada pelo servidor e grupo de controle de banner |
| `consent` | Booleano `enabled`; revogação apaga eventos remotos da conta |
| `events` | Até 50 eventos; ID idempotente por conta, nomes/dimensões em allowlist e consentimento obrigatório |
| `feedback` | Relato editorial criptografado; nota até 500 caracteres e dez envios por conta/dia |
| `backup_get`, `backup_put`, `backup_delete` | Backup da própria conta; CAS por revisão; zlib/base64 até 55.000 caracteres e conteúdo descomprimido até 4 MiB, somente tabelas de progresso permitidas |
| `friend_create`, `friend_join`, `friend_score`, `friend_list` | Código privado, um convidado, sete dias, pontuação limitada ao modo e indicação de ajuda; sem prêmio ou ranking |
| `wallet` | Saldo derivado de consumíveis verificados e gastos confirmados/reservados; não aceita saldo do cliente |
| `wallet_reserve`, `wallet_commit`, `wallet_refund` | Operação idempotente vinculada à conta/instalação; repetição incompatível ou estorno de gasto confirmado é rejeitado |

O worker remove eventos recebidos há mais de 60 dias, mesmo sem uploads novos; inicialização da API e novas escritas também fazem limpeza. Não registrar o corpo de backup ou relatos em logs. Backups são criptografados em repouso e não contêm credenciais comerciais; o ledger comprado é recuperado separadamente. Recuperação de identidade revoga o dispositivo anterior e trata suas reservas inacabadas. Relatos e resultados de amigos são dados do cliente, não provas de desempenho competitivo.
