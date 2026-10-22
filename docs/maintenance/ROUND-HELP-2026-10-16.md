# Tickets e ajuda opcional nas rodadas

Implementação de 16/10/2026. AdMob permanece sem IDs e sem anúncios reais nesta entrega. Não foi gerado APK.

## Economia

- Novas diárias: 10 tickets, renovados à meia-noite UTC.
- Bônus permanecem. Uma diária maior que já havia sido concedida é preservada até a próxima renovação; o saldo não é confiscado pela atualização.
- Ajudas por ticket: 1 ticket, sem duplicar uma ajuda já adquirida.
- Vídeo no saldo: +2 tickets.
- Vídeo na ajuda: crédito verificado de +2, seguido da compra da ajuda por 1. Resultado: ajuda escolhida +1 ticket. Essa equivalência evita que a opção direta tenha menos valor que assistir no saldo.
- Até 3 vídeos recompensados por dia UTC no total, com no máximo 1 vídeo de ajuda por partida. O limite persiste ao sair e voltar.
- Diários e convites de filmes continuam gratuitos; continuar uma partida salva não cobra início novamente.

## Interface e regras

Filmes e Pôsteres têm uma entrada Precisa de ajuda?; métodos de obtenção aparecem somente ao abri-la. Diretor, ano e duração são oferecidos quando os dados existem, sem vender um campo vazio. Valores adquiridos permanecem na partida.

Cores preserva a dica rápida gratuita e oferece orientação de ajustes por ticket/vídeo. A orientação registra os controles no instante da compra e sugere família de tons e brilho/intensidade, sem mostrar HSB/hex exatos nem responder continuamente aos sliders. Usa a penalidade existente de 1 ponto por ajuda; não altera o placar para quem assistiu ao anúncio. Zoom permanece livre.

Tutorial e textos foram atualizados em português, inglês e espanhol. O menu é rolável e foi conferido a 320 px com fonte a 200%. Artes e fontes existentes foram reaproveitadas.

## Integridade e recuperação

- Reserva única por partida, com tentativa de servidor vinculada antes de exibir o anúncio.
- Callback visual do SDK não concede saldo: continua necessária a confirmação SSV/recibo assinado já usada pelo app.
- O diário de recibos conserva a tentativa para reconhecer créditos já entregues. A migração adiciona a coluna em instalações anteriores.
- Recompensa atrasada fica pendente e pode ser recuperada ao sincronizar, sem um segundo vídeo. Reservas interrompidas antes da abertura expiram em 2 minutos; tentativas sem confirmação expiram após a janela do servidor mais tolerância (40 minutos).
- A ajuda só é aplicada à sessão e pergunta originais. Se o destino deixou de ser válido, a compra é cancelada/estornada e o crédito de 2 tickets permanece.
- Persistência de ajuda bem sucedida não é estornada por fechamento da tela. Duplo toque não duplica o benefício.
- Falhas e cancelamentos mantêm a partida utilizável. Nenhum placeholder simula recompensa.

Skill aplicada: secure-code-guardian, na validação dos identificadores, consultas parametrizadas e preservação da confirmação assinada.

## Evidências

`test/round_help_test.dart` cobre saldo/renovação, migração sem perda, concorrência, uso repetido, cancelamento, SSV atrasado, troca de filme, estorno, cota compartilhada e persistência da orientação. `test/round_help_ui_test.dart` exercita as telas reais, aquisição por ticket, o anúncio controlado de teste e os três idiomas em fonte ampliada. A suíte geral também foi executada.

Validação final: 803 testes da suíte geral aprovados; 8 testes de interface aprovados novamente ao gerar as capturas. `flutter analyze --no-pub --fatal-infos` sem problemas. Validadores de uso de arquivos e conformidade de release aprovados.

Galeria local: `docs/preview/round-help/GALERIA.html`. As capturas são renderizações reais do Flutter, sem depender do celular; o anúncio habilitado é um cenário controlado identificado na galeria.
