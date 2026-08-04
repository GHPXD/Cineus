/// An extra piece of information the player can buy mid-game with a ticket.
///
/// Buying a hint does NOT burn a reveal step, so the score is untouched — the
/// cost is paid in tickets instead of points.
enum ExtraHint {
  director,
  year,
  runtime;

  int get ticketCost => 1;


  String get emoji => switch (this) {
        ExtraHint.director => '🎬',
        ExtraHint.year => '📅',
        ExtraHint.runtime => '⏱️',
      };
}
