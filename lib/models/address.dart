/// A delivery address.
///
/// Split into fields rather than one free-text blob so it can be validated,
/// formatted consistently, and handed to a courier API later without
/// re-parsing what the user typed.
class Address {
  final String fullName;
  final String phone;
  final String line1;
  final String line2;
  final String city;
  final String state;
  final String pincode;

  /// Free-text hint for the rider ("opposite the temple, blue gate").
  final String landmark;

  const Address({
    required this.fullName,
    required this.phone,
    required this.line1,
    this.line2 = '',
    required this.city,
    required this.state,
    required this.pincode,
    this.landmark = '',
  });

  /// The address as a courier would read it, one line.
  String get formatted => [
        line1,
        line2,
        landmark,
        city,
        [state, pincode].where((p) => p.trim().isNotEmpty).join(' '),
      ].map((p) => p.trim()).where((p) => p.isNotEmpty).join(', ');

  /// The address over several lines, for the checkout card.
  String get multiline => [
        [line1, line2].where((p) => p.trim().isNotEmpty).join(', '),
        if (landmark.trim().isNotEmpty) landmark.trim(),
        [
          [city, state].where((p) => p.trim().isNotEmpty).join(', '),
          pincode,
        ].where((p) => p.trim().isNotEmpty).join(' — '),
      ].map((p) => p.trim()).where((p) => p.isNotEmpty).join('\n');

  Address copyWith({
    String? fullName,
    String? phone,
    String? line1,
    String? line2,
    String? city,
    String? state,
    String? pincode,
    String? landmark,
  }) =>
      Address(
        fullName: fullName ?? this.fullName,
        phone: phone ?? this.phone,
        line1: line1 ?? this.line1,
        line2: line2 ?? this.line2,
        city: city ?? this.city,
        state: state ?? this.state,
        pincode: pincode ?? this.pincode,
        landmark: landmark ?? this.landmark,
      );

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'phone': phone,
        'line1': line1,
        'line2': line2,
        'city': city,
        'state': state,
        'pincode': pincode,
        'landmark': landmark,
      };

  factory Address.fromJson(Map<String, dynamic> json) => Address(
        fullName: json['fullName'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        line1: json['line1'] as String? ?? '',
        line2: json['line2'] as String? ?? '',
        city: json['city'] as String? ?? '',
        state: json['state'] as String? ?? '',
        pincode: json['pincode'] as String? ?? '',
        landmark: json['landmark'] as String? ?? '',
      );
}
