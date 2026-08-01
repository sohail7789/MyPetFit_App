/// A placed order, carried between the success and tracking screens.
///
/// There is no backend yet, so the reference is generated locally from the
/// order time rather than faking a fixed number from the design.
class OrderReference {
  final String id;
  final int itemCount;
  final DateTime placedAt;
  final DateTime arrivesOn;

  const OrderReference({
    required this.id,
    required this.itemCount,
    required this.placedAt,
    required this.arrivesOn,
  });

  factory OrderReference.create({required int itemCount}) {
    final now = DateTime.now();
    // Short, stable-looking reference derived from the timestamp.
    final suffix = (now.millisecondsSinceEpoch % 100000).toString().padLeft(
          5,
          '0',
        );
    return OrderReference(
      id: '#MPF-$suffix',
      itemCount: itemCount,
      placedAt: now,
      arrivesOn: now.add(const Duration(days: 3)),
    );
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static const _weekdays = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
  ];

  static String _date(DateTime d) => '${d.day} ${_months[d.month - 1]}';

  /// e.g. "Tue, 4 Aug"
  String get arrivalLabel =>
      '${_weekdays[arrivesOn.weekday - 1]}, ${_date(arrivesOn)}';

  /// e.g. "3 items · placed 1 Aug"
  String get summaryLabel =>
      '$itemCount ${itemCount == 1 ? 'item' : 'items'} · '
      'placed ${_date(placedAt)}';

  String get placedAtLabel => '${_date(placedAt)}, ${_time(placedAt)}';

  static String _time(DateTime d) {
    final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final minute = d.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${d.hour < 12 ? 'am' : 'pm'}';
  }
}
