# Operação das sprints 5–12

Complementa [OPERACAO.md](OPERACAO.md). Não houve deploy, compra, anúncio real ou contratação nesta execução. IDs públicos não são segredos; chaves privadas, credenciais das lojas e banco permanecem fora do cliente e do Git.

## Build e produtos

O cliente mantém `CINEUS_ENV`, `CINEUS_COMMERCE_URL` HTTPS, `CINEUS_COMMERCE_PUBLIC_KEY` Ed25519 em base64 e `CINEUS_COMMERCE_KEY_ID`. Os mapas JSON `CINEUS_GOOGLE_PRODUCTS` e `CINEUS_APPLE_PRODUCTS` associam IDs nativos registrados aos IDs internos:

| ID interno | Tipo na loja | Conteúdo |
| --- | --- | --- |
| `cineus.collection.premiere.v1` | Não consumível | 6 itens Estreia |
| `cineus.collection.night.v1` | Não consumível | 6 itens Noite |
| `cineus.collection.city.v1` | Não consumível | 6 itens Cidade |
| `cineus.plus.permanent.v1` | Não consumível | Remoção permanente + 2 itens Plus |
| `cineus.club.monthly.v1` | Assinatura mensal renovável | Benefício temporário + coleção permanente por ciclo válido |

Flags do cliente: `CINEUS_COLLECTIONS`, `CINEUS_PLUS`, `CINEUS_CLUB`, `CINEUS_REWARDED`, `CINEUS_INTERSTITIALS`. Todas falsas por padrão. A disponibilidade da loja, produto consultado, preço localizado, servidor válido e demais condições ainda precisam ser satisfeitas. Nunca colocar um preço proposto como fallback de compra.

No Google, `CINEUS_GOOGLE_CLUB_BASE_PLAN` deve corresponder ao `GOOGLE_CLUB_BASE_PLAN` do servidor. O cliente aceita a fase base mensal `P1M`, sem oferta introdutória, para não anunciar um valor de primeira parcela como mensalidade normal. Apple usa StoreKit 2 com período de um mês. `CINEUS_CLUB_APPROVED=true` só após testes reais, condições claras e conteúdo preparado; o app também exige ciclo atual e seguinte no manifesto. O servidor valida período/estado atual, conta técnica e produto com as lojas. Configurar plano mensal e conferir recibos genuínos faz parte da ativação externa.

O stream de compras é observado antes das ofertas. Pendente/cancelada não concede; transação só é concluída no SDK após gravar verificação no servidor. Uma perda de conexão mantém a transação inacabada para restauração/retentativa. Google acknowledgment usa uma saída durável no ledger; a resposta perdida não concede duas vezes.

## Restauração e suporte

Restaurar compras usa a mesma conta da loja e exige o acesso à identidade comercial. A chave opcional `owner.recovery` é apresentada em Minha coleção para ser guardada privadamente antes de reinstalar/trocar de aparelho. Ela não transfere progresso de jogo. Quando o armazenamento seguro não retém essa identidade, recuperar pela chave antes de restaurar; uma compra vinculada a outra identidade não será transferida apenas por pedido do cliente.

Não prometer restauração automática entre Google/Apple ou sem a chave perdida. Suporte deve confirmar a loja e tratar recuperação por canal privado apropriado; nunca pedir para publicar comprovante, token ou chave num issue público. O repositório público atual serve à triagem e não fornece esse canal privado por si só. Definir esse canal antes de operação comercial.

Cache assinado preserva cosméticos permanentes por origem. Benefícios temporários do Clube têm janela offline de até 24 horas após o snapshot, limitada ainda pela validade da loja. Intersticial exige uma atualização bem-sucedida dos direitos naquele momento; falha de rede/validação suprime a interrupção.

## Anúncios

Configuração adicional: `CINEUS_ADS_REVIEWED`, `CINEUS_ADMOB_NATIVE_CONFIGURED`, `CINEUS_ADS_AUDIENCE` (`general`, `teen` ou `child`) e ad units por plataforma/tipo. Fora de produção, somente publisher oficial de teste `3940256099942544` é aceito; produção rejeita esse publisher. Esta checagem não substitui a revisão do público/Families/privacidade nem o teste em aparelho.

Android: passar a variável de ambiente pública `CINEUS_ADMOB_ANDROID_APP_ID` ao Gradle. iOS: criar o arquivo local ignorado `ios/Flutter/Commerce.xcconfig` com `CINEUS_ADMOB_IOS_APP_ID=ID_PUBLICO_DA_CONTA`. IDs de unidade vêm dos dart-defines `CINEUS_ADMOB_ANDROID_REWARDED`, `CINEUS_ADMOB_ANDROID_INTERSTITIAL`, `CINEUS_ADMOB_IOS_REWARDED` e `CINEUS_ADMOB_IOS_INTERSTITIAL`. Sem configuração, o SDK não é inicializado. Android remove o provider de inicialização automática e permissões de identificador/AdServices; solicitações são não personalizadas e não há solicitação ATT.

Consentimento UMP é atualizado antes de inicializar/carregar; o app verifica se pode solicitar anúncios e oferece opções de privacidade quando requeridas. Isso segue a [integração oficial UMP](https://developers.google.com/admob/flutter/privacy). Conferir App Privacy/Data Safety e a lista SKAdNetwork aplicável à configuração iOS antes da publicação; não há validação de rede iOS neste Windows.

No AdMob: recompensa de **2 tickets**, callback HTTPS `/callbacks/admob`, unidades permitidas em `ADMOB_SSV_UNITS`. O SDK envia identidade e nonce emitido por `/v1/rewards/start`; apenas SSV validado gera recibo. Polls curtos e retomada do app recuperam confirmação tardia. Fechar anúncio ou repetir callback não gera crédito extra. A política mantém três recompensas por dia UTC. Conferir [rewarded Flutter](https://developers.google.com/admob/flutter/rewarded) e configurar o callback na conta real.

Intersticiais exigem ainda `CINEUS_INTERSTITIAL_APPROVED=true`. Políticas persistidas: fora das três primeiras sessões, só resultado de estágio, pelo menos quatro conclusões, dez minutos, máximo dois por dia UTC, 50% de grupo sem exposição. Dez segundos de resultado sem interação criam uma oportunidade; qualquer toque, navegação ou background cancela. Falha no encaixe consome a reserva conservadoramente. Nunca mostrar por botão Próximo/Jogar/Compartilhar/Sair. Plus/Clube válido removem; preferência pode ocultar ofertas de vídeo. O Plus só aparece à venda com essa infraestrutura de interrupção habilitada e válida.

## Publicar coleção compatível

1. Preparar artes via GPT Image, manter origem/prompts, converter/validar, registrar IDs do catálogo compatível e produto/concessões no cliente/servidor. Os dois lançamentos iniciais já estão preparados. Um ID desconhecido ou nova estrutura exige versão compatível do app; o manifesto não executa código nem cadastra produtos desconhecidos silenciosamente.
2. Editar a cópia revisada de `assets/commerce/catalog_v1.json`: revisão crescente, períodos UTC, conteúdo exato e hashes. `python scripts/build_commerce_content.py --pack` copia esse manifesto revisado e os arquivos para `backend/content`; **não regenera o catálogo**. `--initial` é apenas a regeneração explícita do rascunho inicial, nunca um passo sobre conteúdo publicado.
3. Validar assets e previews, configurar `COMMERCE_CONTENT_DIRECTORY` para o pacote imutável e reiniciar a instância com o pacote completo. `/v1/content` assina ambiente/audiência/data; arquivos só são servidos pelo digest autorizado. Nenhum caminho arbitrário enviado pelo cliente é lido.
4. Cliente com `CINEUS_CONTENT_UPDATES=true` usa a mesma origem HTTPS e pin, autentica requisições, limita tamanhos, confere SHA-256, assinatura, formato, dimensões e compatibilidade. Downloads parciais usam Range/If-Range. A ativação troca o ponteiro no banco somente após todos os assets válidos; erros mantêm conteúdo anterior ou o incluído no app.
5. Rollback: publicar **nova revisão maior**, referindo os assets da versão anterior e períodos corrigidos; não reaproveitar um número nem sobrescrever bytes de um digest. O cliente também recupera a versão anterior completa se o cache ativo falhar. Arquivos de atualizações abandonadas são removidos pelo diretório isolado; nada do progresso/inventário é apagado.

O fim da janela de apresentação não revoga posse. Não mudar IDs/ordem das partidas antigas. Revisão do manifesto é independente da revisão do banco e da versão de perguntas Cores.

## Clube e ciclos

`COMMERCE_CLUB_CALENDAR` mapeia mês UTC de início de ciclo para produto de coleção. Outubro→Noite, novembro→Cidade. O servidor exige duas coleções distintas preparadas para configurar Clube; calendário ausente não vira concessão fictícia. Uma obrigação sem conteúdo fica auditada como `cycle_content_missing` e aparece em `check`/`report`, para corrigir e reconciliar.

Google usa assinatura atual e ordem verificada do ciclo. Ciclos conhecidos são reconsultados com backoff independente; RTDN/reembolso persiste antes do processamento. Apple verifica JWS, histórico paginado limitado e estado atual, incluindo graça reconhecida pela loja. Ciclo único concede cosméticos permanentes; cancelamento para renovação mantém validade confirmada, expiração retira só o benefício temporário e reembolso revoga a origem daquele ciclo. Outra compra/Plus válido permanece.

Para um ciclo Google que não foi observado por interrupção longa nas notificações, a API de assinatura atual não deve ser usada para inventar ordens históricas. Verificar explicitamente a ordem conhecida por operação privada:

```text
python -m cineus_commerce --config CONFIG.json reconcile-order --proof-file ARQUIVO_PRIVADO.txt --order-id ORDEM_VERIFICAVEL
```

O CLI consulta provedor e vínculo antes de conceder; o comprovante não é impresso. Proteger/remover o arquivo privado pelo procedimento de suporte. Não expor esse comando como endpoint de concessão. Apple limita a dez páginas por verificação; uma conta além do lote exige revisão/recuperação operacional, sem marcar histórico parcial como completo.

## Parar, medir e recuperar

Desabilitar feature flags na próxima build evita novas ofertas. Para interrupção imediata sem nova build: parar o placement na conta AdMob e/ou desabilitar a oferta na loja; retirar apresentação de conteúdo por manifesto crescente. Não desligar validação, restauração e atendimento de direitos existentes para ocultar uma oferta.

`check` valida integridade, descriptografia, pendências e conteúdo faltante; `reconcile`/`worker` retomam eventos/ordens; `backup` preserva banco consistente. Seguir o guia anterior para guardar também as chaves correspondentes e testar restauração em cópia isolada. Migração SQLite 1→2 é aditiva e preserva compras.

`report --from-epoch INICIO --until-epoch FIM` agrupa plataforma/produto/moeda/estado e ciclos, sem identidade de jogador. Valores brutos, reembolso e líquido conhecido ficam separados; não tratar desconhecido como zero. Conciliar com extratos das lojas e AdMob e registrar custos reais. Telemetria local opcional não é analytics de população e não faz upload automático.
