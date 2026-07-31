enum PetGender { male, female }

enum PetSpecies {
  dog,
  cat,
  bird,
  rabbit,
  other;

  /// Human-readable label used in dropdowns and cards.
  String get label => switch (this) {
        PetSpecies.dog => 'Dog',
        PetSpecies.cat => 'Cat',
        PetSpecies.bird => 'Bird',
        PetSpecies.rabbit => 'Rabbit',
        PetSpecies.other => 'Other',
      };

  /// Emoji used as an avatar glyph. Material Icons doesn't ship distinct
  /// cat/dog/rabbit icons, so we render species with emoji instead — much
  /// clearer than reusing `Icons.pets` for every species.
  String get emoji => switch (this) {
        PetSpecies.dog => '🐶',
        PetSpecies.cat => '🐱',
        PetSpecies.bird => '🐦',
        PetSpecies.rabbit => '🐰',
        PetSpecies.other => '🐾',
      };
}

class OwnerInfo {
  final String name;
  final String contactNumber;
  final String email;
  final String? address;

  const OwnerInfo({
    required this.name,
    required this.contactNumber,
    required this.email,
    this.address,
  });

  OwnerInfo copyWith({
    String? name,
    String? contactNumber,
    String? email,
    String? address,
  }) =>
      OwnerInfo(
        name: name ?? this.name,
        contactNumber: contactNumber ?? this.contactNumber,
        email: email ?? this.email,
        address: address ?? this.address,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'contactNumber': contactNumber,
        'email': email,
        if (address != null) 'address': address,
      };

  factory OwnerInfo.fromJson(Map<String, dynamic> json) => OwnerInfo(
        name: json['name'] as String? ?? '',
        contactNumber: json['contactNumber'] as String? ?? '',
        email: json['email'] as String? ?? '',
        address: json['address'] as String?,
      );
}

class PetInfo {
  final String id;
  final String name;
  final String breed;
  final int ageYears;
  final int ageMonths;
  final PetGender gender;
  final PetSpecies species;
  final double weightKg;
  final double heightCm;
  final String? microchipNumber;
  final String? vetName;
  final String? vetContact;
  final String? photoPath;

  const PetInfo({
    required this.id,
    required this.name,
    required this.breed,
    required this.ageYears,
    required this.ageMonths,
    required this.gender,
    this.species = PetSpecies.dog,
    required this.weightKg,
    required this.heightCm,
    this.microchipNumber,
    this.vetName,
    this.vetContact,
    this.photoPath,
  });

  PetInfo copyWith({
    String? id,
    String? name,
    String? breed,
    int? ageYears,
    int? ageMonths,
    PetGender? gender,
    PetSpecies? species,
    double? weightKg,
    double? heightCm,
    String? microchipNumber,
    String? vetName,
    String? vetContact,
    String? photoPath,
  }) =>
      PetInfo(
        id: id ?? this.id,
        name: name ?? this.name,
        breed: breed ?? this.breed,
        ageYears: ageYears ?? this.ageYears,
        ageMonths: ageMonths ?? this.ageMonths,
        gender: gender ?? this.gender,
        species: species ?? this.species,
        weightKg: weightKg ?? this.weightKg,
        heightCm: heightCm ?? this.heightCm,
        microchipNumber: microchipNumber ?? this.microchipNumber,
        vetName: vetName ?? this.vetName,
        vetContact: vetContact ?? this.vetContact,
        photoPath: photoPath ?? this.photoPath,
      );

  String get ageDisplay {
    if (ageYears > 0 && ageMonths > 0) return '$ageYears yr $ageMonths mo';
    if (ageYears > 0) return '$ageYears yr';
    return '$ageMonths mo';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'breed': breed,
        'ageYears': ageYears,
        'ageMonths': ageMonths,
        'gender': gender.name,
        'species': species.name,
        'weightKg': weightKg,
        'heightCm': heightCm,
        if (microchipNumber != null) 'microchipNumber': microchipNumber,
        if (vetName != null) 'vetName': vetName,
        if (vetContact != null) 'vetContact': vetContact,
        if (photoPath != null) 'photoPath': photoPath,
      };

  factory PetInfo.fromJson(Map<String, dynamic> json) => PetInfo(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        breed: json['breed'] as String? ?? '',
        ageYears: (json['ageYears'] as num?)?.toInt() ?? 0,
        ageMonths: (json['ageMonths'] as num?)?.toInt() ?? 0,
        gender: PetGender.values.firstWhere(
          (g) => g.name == json['gender'],
          orElse: () => PetGender.male,
        ),
        species: PetSpecies.values.firstWhere(
          (s) => s.name == json['species'],
          orElse: () => PetSpecies.dog,
        ),
        weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0,
        heightCm: (json['heightCm'] as num?)?.toDouble() ?? 0,
        microchipNumber: json['microchipNumber'] as String?,
        vetName: json['vetName'] as String?,
        vetContact: json['vetContact'] as String?,
        photoPath: json['photoPath'] as String?,
      );
}

/// Signed consent record — stored alongside owner + pet data so we always
/// know *who* consented and *when*. See [PetInfoProvider.giveConsent].
class ConsentRecord {
  final String signatureName;
  final DateTime signedAt;

  const ConsentRecord({
    required this.signatureName,
    required this.signedAt,
  });

  Map<String, dynamic> toJson() => {
        'signatureName': signatureName,
        'signedAt': signedAt.toIso8601String(),
      };

  factory ConsentRecord.fromJson(Map<String, dynamic> json) => ConsentRecord(
        signatureName: json['signatureName'] as String? ?? '',
        signedAt: DateTime.tryParse(json['signedAt'] as String? ?? '') ??
            DateTime.now(),
      );
}
