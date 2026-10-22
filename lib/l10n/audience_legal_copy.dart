/// Current privacy behavior, including restrictions retained from older versions.
abstract final class AudienceLegalCopy {
  static (String, String) privacy(String language) => switch (language) {
    'pt' => (
      'Privacidade e compras',
      'Esta versão não solicita faixa etária, data de nascimento ou documento. Sem declaração anterior, os anúncios usam tratamento conservador para adolescentes e não são personalizados; as métricas comerciais permanecem desativadas. Restrições declaradas em versões anteriores são preservadas. Compras dependem da autenticação e das restrições da App Store ou Google Play, incluindo controles familiares. A remoção da pergunta não declara nem verifica a idade do jogador.',
    ),
    'es' => (
      'Privacidad y compras',
      'Esta versión no solicita edad, fecha de nacimiento ni documentos. Sin una declaración previa, los anuncios usan tratamiento conservador para adolescentes, sin personalización; las métricas comerciales permanecen desactivadas. Se conservan las restricciones declaradas en versiones anteriores. Las compras requieren la autenticación y restricciones de App Store o Google Play, incluidos los controles familiares. Quitar la pregunta no declara ni verifica la edad del jugador.',
    ),
    _ => (
      'Privacy and purchases',
      'This version does not request an age range, birth date or identity document. Without an earlier declaration, ads use conservative teen treatment without personalization, and commercial metrics remain disabled. Restrictions declared in earlier versions are preserved. Purchases require App Store or Google Play authentication and restrictions, including family controls. Removing the question neither declares nor verifies the player’s age.',
    ),
  };
  static (String, String) terms(String language) => switch (language) {
    'pt' => (
      'Ofertas atuais e direitos anteriores',
      'A oferta atual prioriza tickets, vídeos com recompensa e remoção de anúncios comuns quando disponível. Novas vendas de coleções e assinaturas do Clube estão pausadas. As regras de coleções e Clube abaixo continuam aplicáveis aos direitos anteriores, incluindo restauração e reembolso. Vídeos de tickets e de ajuda compartilham a cota diária exibida; a recompensa corresponde à oferta escolhida, sem somar tickets quando o vídeo libera uma ajuda.',
    ),
    'es' => (
      'Ofertas actuales y derechos anteriores',
      'La oferta actual prioriza tickets, videos con recompensa y quitar anuncios comunes cuando esté disponible. Las nuevas ventas de colecciones y suscripciones del Club están pausadas. Las reglas siguientes de colecciones y Club se mantienen para derechos anteriores, restauraciones y reembolsos. Los videos de tickets y ayuda comparten el límite diario; cada video entrega la recompensa elegida, sin sumar tickets al conceder una ayuda.',
    ),
    _ => (
      'Current offers and existing rights',
      'Current offers prioritize tickets, rewarded videos and regular-ad removal when available. New collection sales and Club subscriptions are paused. The collection and Club terms below still apply to existing rights, restores and refunds. Ticket and help videos share the displayed daily limit; each video delivers the chosen reward, without adding tickets when it unlocks help.',
    ),
  };
}
