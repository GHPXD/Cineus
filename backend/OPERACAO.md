# Operação e recuperação

## Antes de publicar

1. Revisar orçamento total e host. Esta entrega não contrata nem publica nada.
2. Separar sandbox/produção: banco, chaves, credenciais, produtos, ad units e URLs. Fazer cópia segura das chaves; perder AES/HMAC impede recuperar provas e referências.
3. Configurar Google/Apple com permissões mínimas, produtos reais e IDs do aplicativo. Obter certificados Apple da fonte oficial. Nunca incluir essas credenciais em `--dart-define`, assets ou imagem Docker.
4. Implantar **API e worker** na mesma máquina com volume local persistente. `compose.yaml` espera `.secrets/commerce.json`, `/data` gravável pelo UID 10001 e segredos somente leitura. Ajustar permissões no host. A receita Docker não foi executada nesta entrega.
5. Colocar reverse proxy HTTPS com certificado válido, limite de corpo 64 KiB, limite de query e timeouts. Porta da API fica em loopback. Nunca registrar query SSV, Authorization, corpos ou exceções cruas do provedor. Confiar no IP real só de proxy conhecido, após restringir rede e testar a configuração. Por padrão o Python ignora forwarded headers; atrás do proxy o limite por IP é compartilhado, exigindo limite apropriado no proxy antes de liberar público.
6. Configurar RTDN Pub/Sub com JWT OIDC (audience/email/subscription exatos), App Store Server Notifications e AdMob SSV. Conferir payload de ambiente errado, assinatura inválida, replay e produto fora da allowlist.
7. Criar backup externo criptografado e monitoramento: saúde HTTP, disco/WAL, eventos pendentes, erro/backoff de provedor e recibos sem ACK. Não monitorar coletando tokens. `check` informa integridade e contagens; ainda não existe dashboard ou serviço gerenciado de alertas.
8. Validar em sandbox: compra real de teste, pending, reembolso, restauração, resposta perdida, encerramento do processo e retomada. Android Internal Testing e iOS TestFlight com SDKs das sprints 5–6. Conferir Keychain/Keystore nos aparelhos. Revisar retenção, canal privado de suporte, exclusão comercial e declarações das lojas antes de ativar coleta pública.
9. Somente então fixar URL/chave pública/ambiente na build. Manter flags sem benefício implementado desligadas. Produtos sem oferta real não aparecem como compráveis.

## Backup e restauração

`backup --out CAMINHO_NOVO` usa a API de backup do SQLite e verifica integridade. Recusa sobrescrever arquivo existente. Não copiar apenas `.sqlite` enquanto o serviço escreve em WAL.

Definir retenção e frequência conforme o volume de transações; a proposta inicial é backup diário com cópia externa, mais um antes de qualquer migração. Isso é um procedimento a configurar, não um agendamento já instalado. Backup também contém dados comerciais e deve ter acesso restrito e criptografia no destino. Guardar chaves separadamente, com acesso recuperável pelo responsável.

Para restaurar:

1. Pausar API/worker; preservar o volume original e seus WAL/SHM para investigação. Não apagar nem sobrescrever o banco corrente.
2. Restaurar a cópia para **outro caminho** e apontar uma configuração privada para ele, com os mesmos ambiente, bundle/package e chaves AES/HMAC.
3. Rodar `check` com a configuração restaurada: integridade e descriptografia das provas precisam passar.
4. Rodar `reconcile` até escoar pendências e comparar contagens/auditoria. Provedores de teste configurados devem confirmar o estado atual; backup antigo não significa que uma compra reembolsada voltou a ser válida.
5. Validar snapshot, repetição de eventos e crédito único antes de trocar o caminho em operação. Manter rollback preservado. Testar esse procedimento periodicamente.

Há teste automatizado de backup e reabertura com registros/segredos reais de teste, além de teste de perda de resposta e recuperação após reinício. Não foi realizado restore de uma implantação pública.

## Chaves e atualizações

- Ed25519 privada fica no servidor. Rotação demanda `COMMERCE_KEY_ID` novo e distribuição planejada do pin público no app; clientes antigos não aceitam silenciosamente chave diferente. A implementação atual usa um pin por build, sem distribuição remota automática.
- AES/HMAC não podem ser trocadas diretamente: fingerprints impedem abertura incompatível. A migração precisa recriptografar/reindexar em cópia validada. Não há ferramenta de rotação dessas chaves nesta sprint.
- Proteger arquivos com ACL adequada no Windows e usuário exclusivo no Linux; `chmod 600` não substitui conferir ACL do host Windows.
- Atualizar dependências em ramo revisável, repetir testes e ensaiar migração antes do deploy. SQLite de backend está na versão de esquema 1; cache local Flutter no esquema lógico 6. Protocolo assinado permanece v1.

## Compra ou recompensa com problema

Usar somente IDs técnicos sanitizados no suporte. Nunca pedir credenciais de recuperação, chaves de loja ou comprovantes em chamado público. O canal privado de suporte precisa estar definido antes da publicação comercial.

- Compra conhecida sem concessão: verificar auditoria e worker; reconsultar loja. Não conceder por screenshot.
- Acknowledgment Google falhou após commit: worker repete a verificação/ACK; não refazer compra nem duplicar concessão.
- Reembolso: consultar estado atual, revogar apenas a origem correspondente. Outras compras e itens gratuitos permanecem.
- Recompensa com resposta perdida: retomar a mesma instalação e sincronizar; o diário de recibos impede segundo crédito.
- Outro aparelho recebeu estado sem recibo antes reclamado: verificar claim/ACK. Não desbloquear transferência automática; o saldo local antigo não tem confirmação global suficiente.
- Sessão expirada: cliente mantém dispositivo, grava token novo e usa recuperação; perda da resposta é repetível. Reinstalação que perde a identidade exige chave de recuperação guardada privadamente e mesma conta da loja para restauração. Sem a chave, não reassociar comprovantes por pedido do cliente; suporte privado e verificação de titularidade são necessários. Perfil local não serve como autenticação.

## Restrições atuais

Implantação de uma máquina; sem serviço de e-mail, conta social, sincronização de partidas ou saldo global. Ofertas/SDK/ciclos estão implementados; não há assinatura operacional, cobrança real, anúncios reais, compras genuínas validadas ou tráfego comercial ativado. Cache permanente favorece continuidade; benefícios temporários são limitados e interrupções exigem verificação atual. Consulte [operação comercial atualizada](OPERACAO-COMERCIAL.md). Não oferecer garantia de antifraude absoluto em aparelho adulterado.
