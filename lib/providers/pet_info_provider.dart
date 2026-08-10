import 'dart:convert';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pet_info.dart';
import 'dart:io';

import '../services/photo_store.dart';
import '../services/photo_uploader.dart';
import '../models/consent_state.dart';
import '../models/owner_profile.dart';
import '../services/firestore_service.dart';
import '../services/sync_reconciler.dart';
import 'cloud_sync.dart';

class PetInfoProvider extends ChangeNotifier with CloudSync {
  static const int maxPets = 5;
  static const _key = 'pet_info_state';

  /// The cloud source. Injectable for the same reason ProductProvider's is:
  /// the reconciliation this provider does on startup is the part most worth
  /// testing, and it should be reachable without standing up Firestore.
  final FirestoreService _firestore;

  /// Puts photos in Storage. Injectable for the same reason [_firestore] is.
  final PhotoUploader _uploader;

  PetInfoProvider({FirestoreService? service, PhotoUploader? uploader})
      : _firestore = service ?? FirestoreService(),
        _uploader = uploader ?? PhotoUploader();

  /// Turns a freshly picked device path into a durable Storage URL.
  ///
  /// Returns [path] unchanged when it is already a URL — re-uploading an
  /// image that is already in Storage on every subsequent save would burn
  /// bandwidth to produce the same bytes — and when the file has gone, which
  /// is the legacy case: an old record still holding a path whose file a
  /// reinstall removed has nothing left to upload.
  ///
  /// Throws when the upload fails, and that is deliberate. The caller runs
  /// inside [queueSync], so a throw leaves the write queued for retry and
  /// Firestore keeps the value it had. The alternative — swallowing it and
  /// writing the device path — is what put unusable paths in the database in
  /// the first place.
  Future<String?> _durablePhoto(
    String? path,
    Future<String> Function(File file) upload,
  ) async {
    if (path == null || path.isEmpty) return path;
    if (PhotoUploader.isRemote(path)) return path;

    final file = File(path);
    if (!file.existsSync()) return path;

    return upload(file);
  }

  OwnerInfo? _ownerInfo;
  final List<PetInfo> _pets = [];
  int _activePetIndex = 0;
  bool _consentGiven = false;
  ConsentRecord? _consentRecord;
  DateTime? _consentUpdatedAt;
  bool _isLoaded = false;
  Future<void>? _initFuture;

  OwnerInfo? get ownerInfo => _ownerInfo;
  List<PetInfo> get pets => List.unmodifiable(_pets);
  int get activePetIndex => _activePetIndex;
  bool get consentGiven => _consentGiven;
  ConsentRecord? get consentRecord => _consentRecord;

  /// When consent last changed on this device, in UTC. Null until it ever
  /// has, or when the stored decision predates consent being timestamped.
  DateTime? get consentUpdatedAt => _consentUpdatedAt;
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

  /// Reads the persisted snapshot.
  ///
  /// Idempotent and awaitable — the future is cached and returned again on
  /// every later call. main() only *kicks this off*, so without something to
  /// wait on, the cloud reconcilers below could run against a provider that
  /// had not read SharedPreferences yet: each of them persists the whole
  /// snapshot, so an early reconcile wrote `consentGiven: false` over the
  /// stored `true`, and the late-arriving read then appended a second copy of
  /// every pet. [AppStartupProvider.initialize] awaits this first.
  Future<void> init() => _initFuture ??= _readPersisted();

  Future<void> _readPersisted() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        final ownerJson = json['ownerInfo'] as Map<String, dynamic>?;
        if (ownerJson != null) _ownerInfo = OwnerInfo.fromJson(ownerJson);
        final petsJson = json['pets'] as List?;
        if (petsJson != null) {
          _pets
            ..clear()
            ..addAll(petsJson
                .map((e) => PetInfo.fromJson(e as Map<String, dynamic>)));
        }
        _activePetIndex = (json['activePetIndex'] as num?)?.toInt() ?? 0;
        if (_activePetIndex >= _pets.length) {
          _activePetIndex = _pets.isEmpty ? 0 : _pets.length - 1;
        }
        _consentGiven = json['consentGiven'] as bool? ?? false;
        _consentUpdatedAt =
            DateTime.tryParse(json['consentUpdatedAt'] as String? ?? '')
                ?.toUtc();
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

  /// Saves the owner locally, then syncs.
  ///
  /// Returns once the local write is done. The Firestore write is queued
  /// rather than awaited — an owner edit must not fail because the network
  /// is down, and previously a throw here skipped notifyListeners() as well,
  /// so the form appeared to do nothing at all.
  Future<void> setOwnerInfo(OwnerInfo incoming) async {
    // The provider stamps the edit time, never the caller. A screen has no
    // business deciding when a record changed, and a single authority is
    // what makes the timestamps comparable across devices.
    // Captured before the record is replaced, so a photo being *removed*
    // (a stored URL becoming null) can take its Storage object with it.
    // Replacement needs no such handling: the object path is deterministic,
    // so a new upload overwrites the old bytes in place rather than leaving
    // a second object behind.
    final previousPhoto = _ownerInfo?.photoPath;

    final ownerInfo = incoming.copyWith(updatedAt: DateTime.now().toUtc());
    _ownerInfo = ownerInfo;

    if (PhotoUploader.isRemote(previousPhoto) &&
        (ownerInfo.photoPath == null || ownerInfo.photoPath!.isEmpty)) {
      unawaited(_uploader.deleteOwnerPhoto());
    }

    await _persist();
    notifyListeners();

    queueSync('owner', () async {
      // Storage first, Firestore second. The document must never be given a
      // device path again: that path stops resolving the moment the app's
      // container is reassigned — a reinstall, a TestFlight update — which is
      // exactly why saved photos vanished while the record still "had" one.
      final photo = await _durablePhoto(
        ownerInfo.photoPath,
        _uploader.uploadOwnerPhoto,
      );
      _adoptOwnerPhoto(photo);

      await _firestore.saveOwnerProfile(
        OwnerProfile(
          ownerName: ownerInfo.name,
          ownerPhone: ownerInfo.contactNumber,
          ownerEmail: ownerInfo.email,
          ownerPhoto: photo,
          vetName: ownerInfo.vetName,
          vetPhone: ownerInfo.vetContact,
          updatedAt: ownerInfo.updatedAt,
        ),
      );
    });
  }

  /// Local consent in the shape the cloud stores it, or null when this device
  /// has never recorded a decision.
  ///
  /// Null rather than `given: false` on purpose: a fresh install, or the
  /// device someone signs into for the first time, has no opinion to defend,
  /// and reconciliation adopts the account's consent instead of arguing with
  /// it.
  ConsentState? get _localConsent {
    if (!_consentGiven && _consentUpdatedAt == null) return null;
    return ConsentState(
      given: _consentGiven,
      record: _consentRecord,
      // A decision stored by a build that predates consent syncing has no
      // timestamp, so it loses to any dated cloud copy and wins over none.
      updatedAt: _consentUpdatedAt ?? kUnknownUpdatedAt,
    );
  }

  /// Reconciles consent against the cloud.
  ///
  /// Consent used to live only in SharedPreferences and was never written to
  /// Firestore at all, so signing out — which clears that key — or signing in
  /// on any other device left [consentGiven] false with the owner and pets
  /// restored around it. `landingFor` checks consent first, so every returning
  /// user was sent to the consent screen no matter how much of the flow they
  /// had already finished.
  ///
  /// Same newest-wins rule as the owner record, and a local win is queued for
  /// upload — which is also how a device that consented before this existed
  /// gets its decision into the cloud.
  Future<void> loadConsentFromFirestore() async {
    final cloud = await _firestore.getConsent();

    final outcome = reconcileSingle<ConsentState>(
      local: _localConsent,
      cloud: cloud,
      updatedAtOf: (c) => c.updatedAt,
      sameContent: (a, b) => a.sameContentAs(b),
      id: 'consent',
    );

    _logSyncWarnings(outcome.warnings);

    final resolved = outcome.resolved.isEmpty ? null : outcome.resolved.first;
    _consentGiven = resolved?.given ?? false;
    _consentRecord = resolved?.record;
    _consentUpdatedAt =
        resolved == null || resolved.isUndated ? null : resolved.updatedAt;

    await _persist();
    notifyListeners();

    for (final pending in outcome.toUpload) {
      queueSync('consent', () => _firestore.saveConsent(pending));
    }
  }

  /// Reconciles the owner record against the cloud.
  ///
  /// Was "pull and overwrite", which is only safe while local can never be
  /// ahead — and offline-first makes it ahead by design, so an unsynced edit
  /// was destroyed on the next launch. Now the newer side wins and a local
  /// win is queued for upload.
  Future<void> loadOwnerFromFirestore() async {
    final profile = await _firestore.getOwnerProfile();

    final cloud = profile == null
        ? null
        : OwnerInfo(
            name: profile.ownerName,
            contactNumber: profile.ownerPhone,
            email: profile.ownerEmail,
            // Address is local-only — captured at checkout, never round
            // tripped through the owner document — so it is carried across
            // rather than lost when the cloud copy wins.
            address: _ownerInfo?.address,
            vetName: profile.vetName,
            vetContact: profile.vetPhone,
            photoPath: profile.ownerPhoto,
            updatedAt: profile.updatedAt,
          );

    final outcome = reconcileSingle<OwnerInfo>(
      local: _ownerInfo,
      cloud: cloud,
      updatedAtOf: (o) => o.updatedAt,
      sameContent: (a, b) => a.sameContentAs(b),
      id: 'owner',
    );

    _logSyncWarnings(outcome.warnings);
    _ownerInfo = outcome.resolved.isEmpty ? null : outcome.resolved.first;

    await _persist();
    notifyListeners();

    // A local record the cloud has not caught up with. This is also how a
    // write lost to process death is recovered: nothing replays a queue,
    // the timestamps simply say local is ahead.
    for (final pending in outcome.toUpload) {
      queueSync('owner', () => _firestore.saveOwnerProfile(_profileOf(pending)));
    }
  }

  /// The Firestore shape of an [OwnerInfo].
  OwnerProfile _profileOf(OwnerInfo owner) => OwnerProfile(
        ownerName: owner.name,
        ownerPhone: owner.contactNumber,
        ownerEmail: owner.email,
        ownerPhoto: owner.photoPath,
        vetName: owner.vetName,
        vetPhone: owner.vetContact,
        updatedAt: owner.updatedAt,
      );

  void _logSyncWarnings(List<String> warnings) {
    if (!kDebugMode) return;
    for (final warning in warnings) {
      debugPrint('Sync conflict: $warning');
    }
  }

  /// Reconciles the pet list against the cloud, per pet.
  ///
  /// A pet edited on this device while offline keeps its local copy and is
  /// queued; a pet added on another device is adopted.
  Future<void> loadPetsFromFirestore() async {
    final cloud = await _firestore.getPets();

    final outcome = reconcileCollection<PetInfo>(
      local: List<PetInfo>.from(_pets),
      cloud: cloud,
      idOf: (p) => p.id,
      updatedAtOf: (p) => p.updatedAt,
      sameContent: (a, b) => a.sameContentAs(b),
    );

    _logSyncWarnings(outcome.warnings);

    // Keep the active pet pointing at the same animal rather than the same
    // index — reconciliation can reorder or add rows.
    final activeId =
        _activePetIndex < _pets.length ? _pets[_activePetIndex].id : null;

    _pets
      ..clear()
      ..addAll(outcome.resolved);

    final restored = _pets.indexWhere((p) => p.id == activeId);
    _activePetIndex = restored >= 0
        ? restored
        : (_pets.isEmpty ? 0 : _pets.length - 1);

    await _persist();
    notifyListeners();

    for (final pending in outcome.toUpload) {
      queueSync('pet-${pending.id}', () => _firestore.savePet(pending));
    }
  }

  /// Backwards-compatible setter — adds or replaces the active pet.
  Future<void> setPetInfo(PetInfo incoming) async {
    final petInfo = incoming.copyWith(updatedAt: DateTime.now().toUtc());
    if (_pets.isEmpty) {
      _pets.add(petInfo);
    } else {
      _pets[_activePetIndex] = petInfo;
    }

    await _persist();
    notifyListeners();

    queueSync('pet-${petInfo.id}', () => _firestore.savePet(petInfo));
  }

  Future<void> addPet(PetInfo incoming) async {
    if (_pets.length >= maxPets) return;

    final pet = incoming.copyWith(updatedAt: DateTime.now().toUtc());
    _pets.add(pet);
    _activePetIndex = _pets.length - 1;

    await _persist();
    notifyListeners();

    queueSync('pet-${pet.id}', () => _savePetWithPhoto(pet));
  }

  void updatePet(int index, PetInfo incoming) {
    if (index < 0 || index >= _pets.length) return;
    final pet = incoming.copyWith(updatedAt: DateTime.now().toUtc());
    _pets[index] = pet;
    _persist();
    notifyListeners();
    // This never reached Firestore at all, so an edited pet reverted to its
    // original the next time the cloud was read. Same queue as add/set, so
    // repeated edits collapse to one write.
    queueSync('pet-${pet.id}', () => _savePetWithPhoto(pet));
  }

  /// Removes a pet locally and, in the background, from the cloud.
  ///
  /// Order is local-first like every other write here: the row disappears
  /// immediately and the cascade follows. A queued delete for a pet is keyed
  /// the same as a queued save for it, so a delete supersedes any unsent
  /// edit rather than the two racing.
  void removePet(int index) {
    if (index < 0 || index >= _pets.length) return;
    final removed = _pets[index];

    // Take the photo with the record, or storage accumulates images for pets
    // that no longer exist.
    //
    // Which store depends on what the record holds. A Storage URL means the
    // durable object has to go — `PhotoStore.deleteAt` would treat that URL as
    // a filename, find no such file and silently do nothing, which is exactly
    // how removed pets came to leave their photos on the bucket. A legacy
    // device path means the local file, and nothing remote: attempting a
    // Storage delete for it would target an object that never existed.
    if (PhotoUploader.isRemote(removed.photoPath)) {
      unawaited(_uploader.deletePetPhoto(removed.id));
    } else {
      unawaited(PhotoStore().deleteAt(removed.photoPath));
    }

    _pets.removeAt(index);
    if (_activePetIndex >= _pets.length && _pets.isNotEmpty) {
      _activePetIndex = _pets.length - 1;
    }
    _persist();
    notifyListeners();

    // Cascades the assessments subcollection — Firestore does not, and a
    // deleted pet's reports would otherwise linger as orphans.
    queueSync('pet-${removed.id}', () => _firestore.deletePet(removed.id));
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
  ///
  /// Local first then queued, like every other write here: consenting must
  /// not fail because the network is down. The cloud copy is what makes the
  /// decision survive a sign-out or follow the user to another device — see
  /// [loadConsentFromFirestore].
  ///
  /// Returns once the local write is on disk, so a caller that navigates
  /// afterwards cannot outrun it — the same contract [setOwnerInfo] and
  /// [addPet] offer. All three gate the router's landing decision, and a
  /// process death in the unawaited window would have lost the one thing that
  /// sends the user back to this form.
  Future<void> giveConsent({String? signatureName}) async {
    _consentGiven = true;
    // The provider stamps the decision, never the caller — the same rule the
    // owner and pet records follow, and what makes all three comparable
    // across devices.
    _consentUpdatedAt = DateTime.now().toUtc();
    if (signatureName != null && signatureName.trim().isNotEmpty) {
      _consentRecord = ConsentRecord(
        signatureName: signatureName.trim(),
        signedAt: DateTime.now().toUtc(),
      );
    }

    await _persist();
    notifyListeners();

    final consent = _localConsent;
    if (consent != null) {
      queueSync('consent', () => _firestore.saveConsent(consent));
    }
  }

  /// Clear in-memory state only. Use [reset] to also wipe persisted data.
  void resetMemory() {
    _ownerInfo = null;
    _pets.clear();
    _activePetIndex = 0;
    _consentGiven = false;
    _consentRecord = null;
    _consentUpdatedAt = null;
    notifyListeners();
  }

  /// Wipe both in-memory state and the persisted key. Called on sign-out.
  Future<void> reset() async {
    // Anything still waiting belongs to the account signing out; replaying
    // it later would write their data under the next user's credentials.
    clearPendingSyncs();
    _ownerInfo = null;
    _pets.clear();
    _activePetIndex = 0;
    _consentGiven = false;
    _consentRecord = null;
    _consentUpdatedAt = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    notifyListeners();
  }

  /// Uploads [pet]'s photo if it is still a device path, then saves the pet.
  ///
  /// The pet's own id keys the Storage object, which is why this runs here
  /// rather than in the picker: a photo chosen for a pet that did not exist
  /// yet is filed under a draft slot, and only by this point is the real id
  /// known.
  Future<void> _savePetWithPhoto(PetInfo pet) async {
    final photo = await _durablePhoto(
      pet.photoPath,
      (file) => _uploader.uploadPetPhoto(pet.id, file),
    );

    final stored = photo == pet.photoPath ? pet : pet.copyWith(photoPath: photo);
    if (!identical(stored, pet)) _adoptPetPhoto(pet.id, photo);

    await _firestore.savePet(stored);
  }

  /// Replaces the owner's stored photo reference with [photo] locally.
  ///
  /// So the device's own copy of the record holds the URL too. Without it the
  /// local snapshot keeps the device path, and the next cold start restores
  /// that path over the URL the cloud correctly holds.
  void _adoptOwnerPhoto(String? photo) {
    final owner = _ownerInfo;
    if (owner == null || owner.photoPath == photo) return;
    _ownerInfo = owner.copyWith(photoPath: photo);
    _persist();
    notifyListeners();
  }

  void _adoptPetPhoto(String petId, String? photo) {
    final at = _pets.indexWhere((p) => p.id == petId);
    if (at < 0 || _pets[at].photoPath == photo) return;
    _pets[at] = _pets[at].copyWith(photoPath: photo);
    _persist();
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
        if (_consentUpdatedAt != null)
          'consentUpdatedAt': _consentUpdatedAt!.toIso8601String(),
        if (_consentRecord != null) 'consentRecord': _consentRecord!.toJson(),
      }),
    );
  }
}
