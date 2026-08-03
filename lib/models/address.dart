/// What an address is for. The design offers exactly these three.
enum AddressLabel {
  home,
  work,
  other;

  String get display => switch (this) {
        AddressLabel.home => 'Home',
        AddressLabel.work => 'Work',
        AddressLabel.other => 'Other',
      };

  static AddressLabel fromName(String? name) => AddressLabel.values.firstWhere(
        (l) => l.name == name,
        orElse: () => AddressLabel.home,
      );
}

/// A delivery address.
///
/// City, state and PIN are separate fields rather than the single
/// "City, PIN, state" line the design draws. It reads the same on screen, but
/// a six-digit PIN can be validated and a courier or shipping API can consume
/// the parts — neither is possible once they are one free-text string.
class Address {
  /// Stable across edits, so the default pointer and the list stay in sync.
  final String id;

  final AddressLabel label;
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
    required this.id,
    this.label = AddressLabel.home,
    required this.fullName,
    required this.phone,
    required this.line1,
    this.line2 = '',
    required this.city,
    required this.state,
    required this.pincode,
    this.landmark = '',
  });

  /// The address as a courier would read it, on one line.
  String get formatted => [
        line1,
        line2,
        landmark,
        city,
        [state, pincode].where((p) => p.trim().isNotEmpty).join(' '),
      ].map((p) => p.trim()).where((p) => p.isNotEmpty).join(', ');

  /// The address over several lines, for cards and list rows.
  String get multiline => [
        [line1, line2].where((p) => p.trim().isNotEmpty).join(', '),
        if (landmark.trim().isNotEmpty) landmark.trim(),
        [
          [city, state].where((p) => p.trim().isNotEmpty).join(', '),
          pincode,
        ].where((p) => p.trim().isNotEmpty).join(' — '),
      ].map((p) => p.trim()).where((p) => p.isNotEmpty).join('\n');

  Address copyWith({
    String? id,
    AddressLabel? label,
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
        id: id ?? this.id,
        label: label ?? this.label,
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
        'id': id,
        'label': label.name,
        'fullName': fullName,
        'phone': phone,
        'line1': line1,
        'line2': line2,
        'city': city,
        'state': state,
        'pincode': pincode,
        'landmark': landmark,
      };

  /// [fallbackId] covers rows written before addresses carried one — see
  /// the migration in [LocalAddressRepository].
  factory Address.fromJson(Map<String, dynamic> json, {String? fallbackId}) =>
      Address(
        id: json['id'] as String? ??
            fallbackId ??
            'addr_${DateTime.now().microsecondsSinceEpoch}',
        label: AddressLabel.fromName(json['label'] as String?),
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

/// The saved addresses plus which one deliveries default to.
class AddressBook {
  final List<Address> addresses;

  /// Id of the default entry. Null when the book is empty.
  final String? defaultId;

  const AddressBook({this.addresses = const [], this.defaultId});

  bool get isEmpty => addresses.isEmpty;

  /// The default entry, falling back to the first when the pointer is stale.
  Address? get defaultAddress {
    if (addresses.isEmpty) return null;
    for (final a in addresses) {
      if (a.id == defaultId) return a;
    }
    return addresses.first;
  }
}
