# Melhorias de dados e anúncios — 21/10/2026

## Entrega

- Filmes e Pôsteres: um espaço de anúncio nativo após os cards 10, 20, 30 etc.
- Cores: após os cards 5, 10 etc. A contagem corresponde aos **estágios da lista** mostrada na referência; não a um intersticial após partidas concluídas.
- A posição independe de bloqueio, progresso e número de colunas. O anúncio não inicia partida nem cobra tickets. O banner anterior no topo dessas listas foi removido para não somar uma exposição fora do intervalo pedido. O espaço da Home não foi alterado.
- Sem configuração, aparece apenas um espaço reservado claramente identificado. Não há anunciante fictício ou impressão simulada.
- Dados e recuperação usa área segura inferior para manter “Apagar dados de uso” acima da navegação do sistema. Layout verificado com 40 px de área inferior e texto de até 200%.
- “Seu progresso” apresenta o salvamento local, o estado da nuvem e um botão **Gerenciar progresso**. O painel de gerenciamento concentra salvar/restaurar; chave, recuperação e exclusão ficam em uma seção recolhida.

## Verificação funcional da tela

| Função | Estado no código |
| --- | --- |
| Salvamento de partidas no aparelho | Existente; não depende da nuvem |
| Backup manual e restauração | Mantidos; confirmação antes de combinar progresso; status atualizado após operação |
| Situação do backup | Nova consulta autenticada `backup_status`: revisão/data, sem baixar o conteúdo inteiro |
| Recuperação de outro aparelho | Mantida por chave privada; saldo comprado é atualizado após recuperar a identidade, com nova tentativa em foreground se a rede falhar |
| Excluir backup remoto | Mantido com confirmação, mensagem de conclusão e atualização do status; não apaga progresso local |
| Preferência de dados de uso | Carregamento e erro tratados; não habilita envio se a versão não tiver o serviço ativo |
| Apagar dados de uso | Funciona também com o gravador desativado: limpa diagnóstico local e fila de envio, revoga consentimento e preserva jogos/tickets |
| Exclusão no servidor | Confirmação distinta de solicitação pendente; falha de rede mantém a instrução para nova tentativa |
| Concorrência entre coleta e exclusão | Consentimento conferido dentro da transação de gravação; registros posteriores à revogação são recusados |

Antes, o botão podia informar exclusão sem limpar registros locais de diagnóstico e a mensagem “Conecte-se” confundia serviço não configurado com falta de internet. Esses dois comportamentos foram corrigidos. Não foram criadas funções de nuvem fictícias para contornar a ausência de servidor.

## O que falta para ativação real

1. **Nuvem:** publicar a versão atualizada do backend em HTTPS e configurar a URL/chave pública no app. O servidor guarda progresso por titular com criptografia e revisão de backup; a configuração privada fica fora do Flutter. Operação e campos em [ATIVACAO.md](../business/audit-2026-10-19/ATIVACAO.md).
2. **Anúncio nativo:** cadastrar uma unidade nativa própria para cada plataforma e usar `CINEUS_ADMOB_ANDROID_NATIVE` / `CINEUS_ADMOB_IOS_NATIVE`, com `CINEUS_NATIVE_ADS=true`. Também são necessários os app IDs nativos, público/consentimento e flags de revisão já usados pelo restante da publicidade. Nesta arquitetura, o backend fornece os direitos e a configuração assinada do grupo de controle antes de liberar publicidade real. `CINEUS_ADMOB_NATIVE_CONFIGURED` indica a configuração do SDK no app; é diferente da flag do formato `CINEUS_NATIVE_ADS`.
3. **Teste em aparelhos:** verificar consentimento, anúncios oficiais de teste, ausência de preenchimento, ocultação ao sair da aba, falhas e retorno do app em Android/iOS. Não foram usados IDs de produção nem demonstrado anúncio real nesta entrega.
4. **Publicação:** concluir as pendências de direitos e declarações das lojas já registradas no projeto. Nenhum serviço pago ou domínio foi contratado nesta alteração.

A integração usa `NativeAd`, template pequeno, assets e identificação do próprio SDK, descarte de recursos e callbacks de impressão/valor. Não carrega fora da área visível, em aba inativa ou sem consentimento; respeita Plus e o grupo de controle. Em largura útil inferior a 320 px mantém o espaço reservado para evitar corte do template. Segue as [orientações oficiais de templates nativos do AdMob](https://developers.google.com/admob/flutter/native/templates).

## Prints e evidências

[Galeria de telas reais do Flutter](../preview/data-native-2026-10-21/GALERIA.html). As capturas usam dados de teste e placeholders de publicidade. Não foi necessário gerar APK para conferir a interface.

Validação final: **86 testes de regressão Flutter** (incluindo três categorias, opções de dados, consentimento, exclusão concorrente e idiomas), **65 testes do backend**, análise estática estrita sem problemas, validadores de uso e preparo de release aprovados. Não foi repetida toda a suíte do projeto; foram executados os testes pertinentes às alterações. [Logs](../preview/data-native-2026-10-21/validation/README.md).
