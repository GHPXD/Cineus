/// Describes conditional features; availability depends on the configured build.
abstract final class CommerceLegalCopy {
  static List<(String, String)> privacy(String language) => switch (language) {
    'pt' => [
      (
        'Anúncios opcionais',
        'Versões com anúncios habilitados usam Google Mobile Ads e a plataforma de consentimento do Google. Esses serviços podem processar endereço IP, informações do dispositivo, diagnósticos e interações publicitárias conforme sua própria política: policies.google.com/privacy. As solicitações do Cineus são não personalizadas e este app não solicita a permissão de rastreamento da Apple nem o identificador publicitário do Android. Preferências de privacidade ficam em Configurações quando exigidas. Anúncios e compras não são necessários para jogar.',
      ),
      (
        'Dados opcionais e recuperação',
        'Em Dados e recuperação, você pode consentir com métricas de uso: modos, contexto, conclusão de partidas, compras e anúncios. Não incluem nomes, palpites ou comprovantes. Eventos aguardam conexão em uma fila de até 2.000 itens e são retidos por até 60 dias. Desativar a coleta apaga a fila e agenda a exclusão dos eventos do servidor na próxima conexão. Backups são enviados somente ao tocar em salvar e incluem partidas, palpites e catálogos fixados; ficam criptografados no servidor, vinculados à identidade e à chave de recuperação. Você pode apagar o backup. Tickets diários e bônus locais não são transferidos; tickets comprados ficam no ledger do servidor e exigem conexão para uso e recuperação. Confrontos privados expiram em 7 dias e usam placares informados pelo aparelho, sem ranking ou prêmios. Feedback editorial é enviado após sua solicitação e armazenado criptografado para revisão.',
      ),
      (
        'Coleções e eventos',
        'Coleções compatíveis podem ser baixadas do serviço comercial. Missões, descoberta e participação em eventos ficam localmente; a demonstração Aurora não tem patrocinador contratado. O diagnóstico local opcional retém até 2.000 eventos por até 60 dias, incluindo estimativas de receita publicitária, sem envio automático ao Cineus. Patrocinadores recebem apenas relatórios agregados aprovados; não recebem nomes, palpites ou comprovantes.',
      ),
    ],
    'es' => [
      (
        'Anuncios opcionales',
        'Las versiones con anuncios habilitados usan Google Mobile Ads y la plataforma de consentimiento de Google. Estos servicios pueden procesar dirección IP, información del dispositivo, diagnósticos e interacciones publicitarias según policies.google.com/privacy. Cineus solicita anuncios no personalizados y no solicita el permiso de seguimiento de Apple ni el identificador publicitario de Android. Las opciones de privacidad aparecen en Ajustes cuando son necesarias. No es necesario ver anuncios ni comprar para jugar.',
      ),
      (
        'Datos opcionales y recuperación',
        'En Datos y recuperación puedes consentir métricas de modos, partidas, compras y anuncios, sin nombres, intentos ni comprobantes. Una cola de hasta 2.000 eventos espera conexión y la retención máxima es de 60 días. Desactivar borra la cola y solicita borrar los eventos del servidor al reconectar. Las copias solo se envían al guardar explícitamente e incluyen partidas, intentos y catálogos fijados; se cifran en el servidor y se vinculan a tu identidad y clave. Puedes borrar la copia. Los tickets diarios y bonos locales no se transfieren; los comprados están en el ledger del servidor y requieren conexión. Los retos privados caducan en 7 días y usan puntuaciones del dispositivo, sin clasificación ni premios. Los comentarios editoriales se envían tras tu solicitud y se guardan cifrados para revisión.',
      ),
      (
        'Colecciones y eventos',
        'Las colecciones compatibles pueden descargarse del servicio comercial. Misiones, descubrimientos y participación en eventos se guardan localmente; Aurora es una demostración sin patrocinador contratado. El diagnóstico local opcional retiene hasta 2.000 eventos durante un máximo de 60 días, incluidas estimaciones de ingresos publicitarios, sin envío automático a Cineus. Los patrocinadores reciben únicamente informes agregados aprobados; no reciben nombres, intentos ni comprobantes.',
      ),
    ],
    _ => [
      (
        'Optional ads',
        'Builds with ads enabled use Google Mobile Ads and Google consent tools. These services may process IP addresses, device information, diagnostics and ad interactions under policies.google.com/privacy. Cineus requests non-personalized ads and requests neither Apple tracking permission nor the Android advertising identifier. Privacy choices appear in Settings when required. Ads and purchases are not required to play.',
      ),
      (
        'Optional data and recovery',
        'In Data and recovery you can opt into mode, gameplay, purchase and ad metrics without names, guesses or purchase proofs. Up to 2,000 events wait for connection and are retained for at most 60 days. Disabling collection erases the queue and requests server event deletion on reconnection. Backups upload only when you explicitly save, include games, guesses and pinned catalogs, and are encrypted on the server and bound to your identity and recovery key. You can delete the backup. Daily tickets and local bonuses do not transfer; purchased tickets live in the server ledger and require connection to spend or recover. Private challenges expire after 7 days and use device-reported scores with no ranking or prizes. Editorial feedback is sent after your request and stored encrypted for review.',
      ),
      (
        'Collections and events',
        'Compatible collections may download from the commerce service. Missions, discoveries and event participation stay locally; Aurora is a demonstration without a contracted sponsor. Optional local diagnostics retain up to 2,000 events for up to 60 days, including ad revenue estimates, without automatic transmission to Cineus. Sponsors receive approved aggregate reports only, never names, guesses or purchase proofs.',
      ),
    ],
  };
  static List<(String, String)> terms(String language) => switch (language) {
    'pt' => [
      (
        'Compras, Clube e restauração',
        'Preços e confirmação de pagamento são apresentados pela loja. Coleções e Plus são compras únicas; o Clube é mensal, com renovação automática e cancelamento pela loja. O Clube concede a coleção do ciclo verificado e remove interrupções durante a vigência; o Plus remove interrupções permanentemente. Cosméticos de ciclos válidos permanecem após o fim da assinatura. Reembolsos podem revogar a origem correspondente. A restauração exige a mesma conta da loja e o acesso comercial; guarde a chave de recuperação antes de reinstalar ou trocar de aparelho. A chave permite recuperar o backup de progresso salvo explicitamente e o saldo comprado da mesma identidade; não promete compartilhar assinaturas ou produtos entre contas de loja. Vídeos são opcionais e concedem 2 tickets após confirmação, limitados a 3 recompensas por dia UTC. Eventos gratuitos seguem o período e a meta exibidos.',
      ),
    ],
    'es' => [
      (
        'Compras, Club y restauración',
        'La tienda muestra precios y confirma el pago. Las colecciones y Plus son compras únicas; el Club es mensual, se renueva automáticamente y se cancela desde la tienda. El Club concede la colección del ciclo verificado y elimina interrupciones durante su vigencia; Plus las elimina permanentemente. Los cosméticos de ciclos válidos permanecen al finalizar la suscripción. Los reembolsos pueden revocar el origen correspondiente. Restaurar requiere la misma cuenta de tienda y acceso comercial; guarda la clave de recuperación antes de reinstalar o cambiar de dispositivo. La clave recupera la copia de progreso guardada explícitamente y el saldo comprado de la misma identidad; no comparte suscripciones entre cuentas de tienda. Los vídeos son opcionales y conceden 2 tickets tras confirmación, hasta 3 recompensas por día UTC. Los eventos gratuitos siguen el período y objetivo mostrados.',
      ),
    ],
    _ => [
      (
        'Purchases, Club and restore',
        'The store displays prices and confirms payment. Collections and Plus are one-time purchases; Club is a monthly auto-renewing subscription cancelled through the store. Club grants the verified cycle collection and removes interruptions while valid; Plus removes interruptions permanently. Cosmetics from valid cycles remain after subscription expiry. Refunds may revoke the corresponding origin. Restore requires the same store account and commerce access; save the recovery key before reinstalling or changing devices. The key recovers an explicitly saved progress backup and the purchased wallet of the same identity; it does not share subscriptions between store accounts. Videos are optional and grant 2 tickets after confirmation, up to 3 rewards per UTC day. Free events follow the displayed dates and goal.',
      ),
    ],
  };
}
