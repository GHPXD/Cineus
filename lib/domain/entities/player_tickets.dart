class TicketDebit {
  final int daily;
  final int extra;
  final String date;

  const TicketDebit({
    required this.daily,
    required this.extra,
    required this.date,
  });

  int get total => daily + extra;
}

class PlayerTickets {
  final int dailyTickets;
  final int extraTickets;
  final String lastResetDate;

  static const int maxDailyTickets = 20;

  const PlayerTickets({
    this.dailyTickets = maxDailyTickets,
    this.extraTickets = 0,
    required this.lastResetDate,
  });

  int get total => dailyTickets + extraTickets;
  bool get hasTickets => total > 0;

  PlayerTickets copyWith({
    int? dailyTickets,
    int? extraTickets,
    String? lastResetDate,
  }) {
    return PlayerTickets(
      dailyTickets: dailyTickets ?? this.dailyTickets,
      extraTickets: extraTickets ?? this.extraTickets,
      lastResetDate: lastResetDate ?? this.lastResetDate,
    );
  }
}
