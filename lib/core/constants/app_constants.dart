abstract final class AppConstants {
  static const String appName = 'Cineus';
  static const String dbName = 'cineus.db';

  /// Schema version. Bumping this runs `DatabaseHelper._onUpgrade`, which
  /// re-runs the idempotent `ensure*` migrations.
  static const int dbVersion = 1;

  /// Version of the bundled catalogue (movies + clues).
  ///
  /// BUMP THIS whenever `assets/cineus_v1_seed.json` changes. On the next
  /// launch the content tables are refreshed from the asset while player data
  /// (sessions, stage progress, tickets) is left untouched.
  ///
  /// Without this, the asset database was only ever copied when no local file
  /// existed, so an updated catalogue never reached anyone who already had the
  /// app installed.
  static const int contentVersion = 1;

  /// The first day of challenges (epoch).
  ///
  /// MUST be UTC: the whole app defines "day" in UTC so every player gets the
  /// same movie at the same instant. Using a local DateTime here silently
  /// shifted every challenge number by one in negative UTC offsets, because
  /// `difference` compares absolute instants, not calendar dates.
  static final DateTime challengeEpoch = DateTime.utc(2025, 1, 1);

  /// Total clues per movie.
  static const int totalClues = 10;

  /// Starting score (with 1 clue revealed).
  static const int maxScore = 10;

  /// Number of films per stage group.
  static const int stageSize = 10;

  /// Free daily tickets each player receives at midnight.
  static const int dailyTickets = 20;

  /// Visual game total reveal levels.
  static const int visualLevels = 5;

  /// Max visual game score (guessing at blur level 1).
  static const int maxVisualScore = 5;

  /// Splash screen display duration.
  static const Duration splashDuration = Duration(milliseconds: 2500);

  /// Default animation durations.
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationMedium = Duration(milliseconds: 600);
  static const Duration animationSlow = Duration(milliseconds: 800);

  /// Search debounce duration.
  static const Duration searchDebounce = Duration(milliseconds: 300);

  /// Max characters for guess input.
  static const int maxGuessInputLength = 200;

  /// Hash constants for deterministic daily selection.
  static const int dailyHashConstant = 2654435761;
  static const int posterHashConstant = 1640531527;

  /// Shuffle seed multiplier for clue (Dicas) stage lists.
  static const int cluesStageSeed = 1234567891;

  /// Shuffle seed multiplier for poster stage lists (different from clues).
  static const int posterStageSeed = 987654321;

  /// Ordered clue categories (from most abstract to most obvious).
  static const List<String> clueCategories = [
    'Atmosfera',
    'Estilo Visual',
    'Temática',
    'Narrativa',
    'País / Época',
    'Trilha Sonora',
    'Prêmios',
    'Diretor',
    'Elenco',
    'Tagline Oficial',
  ];

  /// Clue category emojis for visual representation.
  /// Maps both the original fixed categories and the dynamic Gemini categories.
  static const Map<String, String> clueCategoryEmojis = {
    // Original fixed categories
    'Atmosfera': '🌫️',
    'Estilo Visual': '🎨',
    'Temática': '💡',
    'Narrativa': '📖',
    'País / Época': '🌍',
    'Trilha Sonora': '🎵',
    'Prêmios': '🏆',
    'Diretor': '🎬',
    'Elenco': '⭐',
    'Tagline Oficial': '💬',
    // Dynamic Gemini categories
    'Conceito': '💭',
    'Trama': '📖',
    'Mecânica': '⚙️',
    'Contexto': '🌍',
    'Revelação': '🔍',
    'Personagem': '👤',
    'Personagens': '👥',
    'Protagonista': '🦸',
    'Antagonista': '😈',
    'Vilão': '😈',
    'Cenário': '🏔️',
    'Ambiente': '🌆',
    'Ambientação': '🌃',
    'Local': '📍',
    'Localização': '📍',
    'Lugar': '📍',
    'Conflito': '⚔️',
    'Combate': '⚔️',
    'Guerra': '⚔️',
    'Ação': '💥',
    'Aventura': '🗺️',
    'Drama': '🎭',
    'Terror': '👻',
    'Mistério': '🕵️',
    'Investigação': '🔎',
    'Suspeita': '🤔',
    'Simbolismo': '🔮',
    'Simbologia': '🔮',
    'Símbolo': '🔮',
    'Filosofia': '📜',
    'Ciência': '🔬',
    'Tecnologia': '💻',
    'Ficção': '🚀',
    'Música': '🎵',
    'Visual': '🎨',
    'Estética': '🎨',
    'Estilo': '🎨',
    'Época': '📅',
    'Cultura': '🌐',
    'Sociedade': '🏛️',
    'Poder': '👑',
    'Poderes': '⚡',
    'Identidade': '🎭',
    'Transformação': '🦋',
    'Evolução': '📈',
    'Jornada': '🛤️',
    'Viagem': '✈️',
    'Missão': '🎯',
    'Objetivo': '🎯',
    'Descoberta': '💡',
    'Destino': '🌟',
    'Origem': '🌱',
    'Início': '▶️',
    'Final': '🏁',
    'Desfecho': '🏁',
    'Clímax': '📈',
    'Conclusão': '✅',
    'Traição': '🗡️',
    'Redenção': '🕊️',
    'Sobrevivência': '🏕️',
    'Perigo': '⚠️',
    'Risco': '⚠️',
    'Ameaça': '☠️',
    'Tensão': '😰',
    'Caos': '🌀',
    'Sentimento': '❤️',
    'Relação': '🤝',
    'Conexão': '🔗',
    'Encontro': '🤝',
    'Grupo': '👥',
    'Equipe': '👥',
    'Aliado': '🤝',
    'Aliados': '🤝',
    'Habilidade': '🏹',
    'Habilidades': '🏹',
    'Estratégia': '♟️',
    'Decisão': '⚖️',
    'Dilema': '⚖️',
    'Premissa': '📋',
    'Estrutura': '🏗️',
    'Elemento': '🧩',
    'Elementos': '🧩',
    'Dinâmica': '🔄',
    'Processo': '📊',
    'Efeito': '✨',
    'Impacto': '💥',
    'Mudança': '🔄',
    'Frase': '💬',
    'Diálogo': '💬',
    'Pista': '🔑',
    'Sinal': '📡',
    'Evidência': '🧾',
    'Confirmação': '✅',
    'Foco': '🎯',
    'Destaque': '⭐',
    'Diferencial': '💎',
    'Evento': '📅',
    'Incidente': '🚨',
    'Momento': '⏳',
    'Artefato': '🏺',
    'Objeto': '📦',
    'Recurso': '🔧',
    'Resgate': '🆘',
    'Retorno': '↩️',
    'Reviravolta': '🔀',
    'Cena': '🎬',
    'Clima': '🌡️',
    'Mundo': '🌍',
    'Universo': '🌌',
    'Lenda': '📜',
    'Mítica': '🐉',
    'Franquia': '🎞️',
    'História': '📚',
    'Exposição': '📢',
    'Resumo': '📝',
    'Treinamento': '🏋️',
    'Exploração': '🧭',
    'Perfil': '📋',
    'Pessoal': '👤',
    'Motivação': '🔥',
    'Desafio': '🏆',
    'Dificuldade': '😤',
    'Conquista': '🥇',
    'Rivalidade': '🤺',
    'Rotina': '🔁',
    'Status': '📊',
    'Queda': '📉',
    'Falha': '❌',
    'Inimigo': '😠',
    'Inimigos': '😠',
    'Resposta': '💡',
    'Condição': '📋',
    'Consequência': '➡️',
    'Acordo': '🤝',
    'Negócios': '💼',
    'Disfarce': '🎭',
    'Fenômeno': '🌟',
    'Humanidade': '🌏',
    'Jogo': '🎲',
    'Realidade': '🪞',
    'Seres': '👽',
    'Teoria': '🧪',
    'Veículo': '🚗',
    'Ícone': '🌟',
    'Óbvia': '💬',
    'Escala': '📏',
    'Estado': '🏳️',
    'Fator': '🔢',
    'Mantra': '🧘',
    'Método': '📐',
    'Regra': '📏',
    'Desenvolvimento': '📈',
    'Susto': '😱',
    'Companhia': '🏢',
    'Desejo': '✨',
    'Progresso': '📈',
    'Punição': '⚖️',
    'Manifestação': '✨',
  };

  /// Fallback emoji for unmapped categories.
  static const String defaultCategoryEmoji = '🎬';

  /// Returns emoji for a category, with fallback.
  static String emojiForCategory(String category) {
    return clueCategoryEmojis[category] ?? defaultCategoryEmoji;
  }
}
