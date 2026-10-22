/// A server anchor advances using a monotonic clock, independent of date edits.
class TrustedTime {
  DateTime? _anchor;
  final Stopwatch _elapsed = Stopwatch();
  DateTime now() => _anchor?.add(_elapsed.elapsed) ?? DateTime.now();
  bool get fresh =>
      _anchor != null && _elapsed.elapsed < const Duration(hours: 24);
  void accept(int seconds) {
    _anchor = DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);
    _elapsed
      ..reset()
      ..start();
  }
}
