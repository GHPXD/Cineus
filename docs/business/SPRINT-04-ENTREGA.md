# Sprint 4 — direitos, validação e concessões

Implementação de 14/10/2026. Backend e integração Flutter preparados e testados localmente. **Sem deploy, contratação, cobranças ou validação genuína das lojas/rede de anúncios.** A coleção continua em prévia; não há oferta comprável fictícia.

## Entrega

- API FastAPI com SQLite persistente, transações atômicas, auditoria, origem única de compra e processamento idempotente. Comprovantes/eventos criptografados com AES-GCM, identificadores opacos HMAC e snapshots assinados com Ed25519. Segredos separados por função e ambiente, fora do cliente/Git.
- Adapters Google Play e Apple consultam a transação atual e verificam produto, aplicação, ambiente, titularidade, estado e revogação. Google acknowledgment ocorre após gravar o direito, com repetição em caso de falha. Notificações autenticadas são persistidas antes do processamento. Resposta antiga em voo não desfaz revogação mais recente.
- Callback AdMob SSV verifica assinatura sobre a query original, ad unit permitida, valor, titular e nonce. Crédito de **dois tickets, até três por dia UTC por identidade comercial**, registrado uma vez. SDK que exibe o anúncio ainda pertence à Sprint 6.
- Worker retoma verificações, notificações e confirmações pendentes; backoff e lotes limitados evitam que uma falha bloqueie todas as origens. Endpoints com limites de abuso, corpos restritos, erros sanitizados, headers de segurança e sem access logs contendo tokens.
- Flutter revalida snapshots assinados antes de aplicar posse. Cache offline preserva o último estado confiável em falha de rede, e revisões antigas não o substituem. Remover uma origem não apaga outra origem válida ou os itens gratuitos; equipamento inválido usa alternativa gratuita.
- Recibo, movimentação e saldo local são confirmados na mesma transação antes do ACK ao servidor. Resposta perdida e reinício da mesma instalação não duplicam recompensa. Diário de recibos não é eliminado pela limpeza do diagnóstico.
- Identidade técnica aleatória persistida antes do primeiro HTTP, sem cadastro obrigatório para jogar. Credenciais em Keystore/Keychain; recuperação e renovação de sessão repetíveis após perda de resposta. Arquivos secretos comerciais excluídos do backup Android e entitlement Keychain adicionado no iOS.
- Inicialização/retomada sincronizam sem bloquear gameplay quando o backend está configurado. Sem URL HTTPS e pin público válidos, não há conexão comercial. Integração comercial web desativada. Checkout/restauração nativos ficam na Sprint 5.

Não houve nova tela ou arte nesta etapa. Fredoka/Nunito, navegação, coleção gratuita e fluxos atuais foram preservados. Sem APK e sem apresentação de antes/depois, conforme combinado.

## Verificação

- **38 testes do backend passaram**: repetição e concorrência, tentativa de usar compra alheia, rollback, revogação por origem, callbacks inválidos/conflitantes/antigos, conta/ambiente/produto incorretos, assinatura ECDSA, rate limit, recuperação, backup e reabertura.
- **19 novos testes Flutter passaram**: envelope Ed25519 produzido em Python, adulteração, destinatário/ambiente errado, revisão antiga, persistência, revogação independente, crédito único e renovação após resposta perdida. Os provedores externos desses testes são controlados; não são compras reais.
- Análise Flutter sem problemas; validadores de uso, conformidade, origem e transparência dos assets passaram. XML nativo bem formado, cópias de privacidade idênticas e dependências Python sem conflitos detectados.
- Smoke HTTP local de verdade: saúde e cadastro 200, snapshot com assinatura Ed25519 válida, ausência de bearer 401, compra/anúncio sem provedor configurado 503 e nenhum benefício concedido. Processo local encerrado após a verificação.
- CLI de integridade/descriptografia e backup consistente executados. Configuração, banco e backup locais contêm apenas identidade fictícia de teste e estão ignorados pelo Git.

Regressão Flutter completa consolidada: **748 testes passaram**, sem falhas, em aproximadamente 4 minutos e 26 segundos. Esse resultado inclui os 19 testes novos e os fluxos anteriores do aplicativo.

Logs locais em `docs/maintenance/monetizacao-sprint-04-backend.log`, `monetizacao-sprint-04-client.log`, `monetizacao-sprint-04-http.log`, `monetizacao-sprint-04-analyze.log` e `monetizacao-sprint-04-tests-final.log`. CI acrescenta testes Python com dependências fixadas. As fontes Google/Apple/AdMob e os contratos estão no [README do backend](../../backend/README.md).

## Operação preparada, ainda pendente

| Item | Estado real |
| --- | --- |
| Validação, ledger, callbacks, cache e reconciliação | Implementados e testados localmente |
| Configuração e banco sandbox local | Gerados com chaves aleatórias; nenhum provedor habilitado |
| Google Play / App Store | Credenciais, produtos reais, notificações e provas genuínas pendentes |
| AdMob | Conta/ad units, callback publicado e confirmação genuína pendentes; SDK na Sprint 6 |
| Hospedagem / HTTPS / backups externos | Receita Compose de uma instância preparada; não executada nem contratada |
| Custo operacional | Arquitetura e itens de orçamento definidos; preço depende da cotação antes de contratar |
| Android / iOS em aparelho | Keystore/Keychain, compra e restauração precisam de teste nativo; iOS exige ambiente Apple |
| Retenção e atendimento comercial | Definir política operacional e canal privado antes de coleta pública |
| Assinatura Clube | Configuração rejeitada nesta etapa; ciclo completo é Sprint 10 |

O Compose limita API e worker a 256 MiB cada e conserva SQLite em volume local. Esses limites são iniciais, não medição de capacidade nem custo completo. Host/SO, proxy, domínio, tráfego, monitoramento e backup externo precisam de orçamento. Não foi assumida mensalidade gratuita ou autorizado gasto.

## Limites explícitos

A identidade comercial não sincroniza partidas, saldo ou nome de perfil. Não há promessa de restauração Android↔iOS. Recuperação técnica depende da credencial preservada; histórico nativo da loja será conectado na Sprint 5.

Um recibo já reclamado fica vinculado à instalação de entrega. Se o aparelho for perdido entre claim e ACK, a transferência automática é bloqueada para evitar segundo crédito; exige reconciliação de suporte. Limite por identidade anônima não representa unicidade de pessoa, e o saldo inteiro ainda não é um ledger remoto.

Uma compra permanente continua disponível offline pelo último cache confiável; revogação chega quando o dispositivo recebe atualização válida. Aparelho adulterado, relógio manipulado e rollback de banco não têm garantia absoluta de antifraude. Políticas de assinatura e outras proteções específicas serão tratadas nas sprints correspondentes.

Guias: [configuração](../../backend/README.md), [protocolo](../../backend/PROTOCOLO.md), [operação, backup e recuperação](../../backend/OPERACAO.md). A privacidade PT/EN/ES explica o serviço opcional e diferencia dados locais de registros comerciais.

Próxima: **Sprint 5 — checkout e restauração Google Play/App Store**, conectados à autoridade preparada nesta entrega.
