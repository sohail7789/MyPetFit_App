import 'dart:convert';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pet_info.dart';
import '../services/photo_store.dart';

class PetInfoProvider extends ChangeNotifier {
  static const int maxPets = 5;
  static const _key = 'pet_info_state';

  OwnerInfo? _ownerInfo;
  final List<PetInfo> _pets = [];
  int _activePetIndex = 0;
  bool _consentGiven = false;
  ConsentRecord? _consentRecord;
  bool _isLoaded = false;

  OwnerInfo? get ownerInfo => _ownerInfo;
  List<PetInfo> get pets => List.unmodifiable(_pets);
  int get activePetIndex => _activePetIndex;
  bool get consentGiven => _consentGiven;
  ConsentRecord? get consentRecord => _consentRecord;
  bool get canAddPet => _pets.length < maxPets;
  int get petCount => _pets.length;
  bool get isLoaded => _isLoaded;

  /// The currently selected pet (used by dashboard, quiz, etc.).
  PetInfo? get activePet =>
      _pets.isNotEmpty && _activePetIndex < _pets.length
          ? _pets[_activePetIndex]
          : null;

  /// Backwards-compatible getter — returns active pet.
  PetInfo? get petInfo => activePet;

  bool get isComplete =>
      _ownerInfo != null && _pets.isNotEmpty && _consentGiven;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        final ownerJson = json['ownerInfo'] as Map<String, dynamic>?;
        if (ownerJson != null) _ownerInfo = OwnerInfo.fromJson(ownerJson);
        final petsJson = json['pets'] as List?;
        if (petsJson != null) {
          _pets.addAll(petsJson
              .map((e) => PetInfo.fromJson(e as Map<String, dynamic>)));
        }
        _activePetIndex = (json['activePetIndex'] as num?)?.toInt() ?? 0;
        if (_activePetIndex >= _pets.length) {
          _activePetIndex = _pets.isEmpty ? 0 : _pets.length - 1;
        }
        _consentGiven = json['consentGiven'] as bool? ?? false;
        final consentJson = json['consentRecord'] as Map<String, dynamic>?;
        if (consentJson != null) {
          _consentRecord = ConsentRecord.fromJson(consentJson);
        }
      } catch (_) {
        // Corrupt payload — start empty.
      }
    }
    _isLoaded = true;
    notifyListeners();
  }

  void setOwnerInfo(OwnerInfo ownerInfo) {
    _ownerInfo = ownerInfo;
    _persist();
    notifyListeners();
  }

  /// Backwards-compatible setter — adds or replaces the active pet.
  void setPetInfo(PetInfo petInfo) {
    if (_pets.isEmpty) {
      _pets.add(petInfo);
    } else {
      _pets[_activePetIndex] = petInfo;
    }
    _persist();
    notifyListeners();
  }

  void addPet(PetInfo pet) {
    if (_pets.length >= maxPets) return;
    _pets.add(pet);
    _activePetIndex = _pets.length - 1;
    _persist();
    notifyListeners();
  }

  void updatePet(int index, PetInfo pet) {
    if (index < 0 || index >= _pets.length) return;
    _pets[index] = pet;
    _persist();
    notifyListeners();
  }

  void removePet(int index) {
    if (index < 0 || index >= _pets.length) return;
    // Take the photo file with the record, or the sandbox accumulates
    // images for pets that no longer exist. Deleted by path rather than by
    // slot: a photo picked before the pet was saved is filed under a draft
    // name, which the pet's own slot would not match.
    unawaited(PhotoStore().deleteAt(_pets[index].photoPath));
    _pets.removeAt(index);
    if (_activePetIndex >= _pets.length && _pets.isNotEmpty) {
      _activePetIndex = _pets.length - 1;
    }
    _persist();
    notifyListeners();
  }

  void setActivePet(int index) {
    if (index < 0 || index >= _pets.length) return;
    _activePetIndex = index;
    _persist();
    notifyListeners();
  }

  /// Records the user's consent. The [signatureName] is captured from the
  /// signature TextField on [ConsentScreen] and stored alongside a UTC
  /// timestamp so we always know *who* consented and *when*.
  void giveConsent({String? signatureName}) {
    _consentGiven = true;
    if (signatureName != null && signatureName.trim().isNotEmpty) {
      _consentRecord = ConsentRecord(
        signatureName: signatureName.trim(),
        signedAt: DateTime.now().toUtc(),
      );
    }
    _persist();
    notifyListeners();
  }

  /// Clear in-memory state only. Use [reset] to also wipe persisted data.
  void resetMemory() {
    _ownerInfo = null;
    _pets.clear();
    _activePetIndex = 0;
    _consentGiven = false;
    _consentRecord = null;
    notifyListeners();
  }

  /// Wipe both in-memory state and the persisted key. Called on sign-out.
  Future<void> reset() async {
    _ownerInfo = null;
    _pets.clear();
    _activePetIndex = 0;
    _consentGiven = false;
    _consentRecord = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode({
        if (_ownerInfo != null) 'ownerInfo': _ownerInfo!.toJson(),
        'pets': _pets.map((p) => p.toJson()).toList(),
        'activePetIndex': _activePetIndex,
        'consentGiven': _consentGiven,
        if (_consentRecord != null) 'consentRecord': _consentRecord!.toJson(),
      }),
    );
  }
}
