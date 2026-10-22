class TicketDebit {
  final int daily;
  final int extra;
  final String date;
  final String? paidOperation;
  final int paid;

  const TicketDebit({
    required this.daily,
    required this.extra,
    required this.date,
    this.paidOperation,
    this.paid = 0,
  });

  int get total => daily + extra + paid;
}

class PlayerTickets {
  final int dailyTickets;
  final int extraTickets;
  final int paidTickets;
  final String lastResetDate;

  static const int maxDailyTickets = 10;

  const PlayerTickets({
    this.dailyTickets = maxDailyTickets,
    this.extraTickets = 0,
    this.paidTickets = 0,
    required this.lastResetDate,
  });

  int get total => dailyTickets + extraTickets + paidTickets;
  bool get hasTickets => total > 0;

  PlayerTickets copyWith({
    int? dailyTickets,
    int? extraTickets,
    int? paidTickets,
    String? lastResetDate,
  }) {
    return PlayerTickets(
      dailyTickets: dailyTickets ?? this.dailyTickets,
      extraTickets: extraTickets ?? this.extraTickets,
      paidTickets: paidTickets ?? this.paidTickets,
      lastResetDate: lastResetDate ?? this.lastResetDate,
    );
  }
}
