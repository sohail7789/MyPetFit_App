import 'package:mypetfit_app/models/consent_state.dart';
import 'package:mypetfit_app/models/owner_profile.dart';
import 'package:mypetfit_app/models/pet_info.dart';
import 'package:mypetfit_app/models/product.dart';
import 'package:mypetfit_app/models/score_result.dart';
import 'package:mypetfit_app/services/firestore_service.dart';

/// An in-memory stand-in for one account's Firestore documents.
///
/// Enough to exercise the startup reconcilers for real — consent, owner and
/// pets all round-trip through it — so the restore path can be tested as it
/// actually runs rather than one reconcile call at a time.
class FakeCloud implements FirestoreService {
  FakeCloud({
    this.consent,
    this.owner,
    List<PetInfo>? pets,
    Map<String, List<ScoreResult>>? assessments,
    this.offline,
  })  : pets = [...?pets],
        assessments = {
          for (final e in (assessments ?? {}).entries) e.key: [...e.value],
        };

  ConsentState? consent;
  OwnerProfile? owner;
  List<PetInfo> pets;

  /// Stored reports per pet id. Seeding these and calling
  /// `loadAssessmentsFromFirestore` gives a QuizProvider real history through
  /// its own restore path, rather than needing a test-only setter on it.
  Map<String, List<ScoreResult>> assessments;

  /// When set, every read throws it — the offline case.
  final Object? offline;

  /// Reads served, so a test can assert the cloud was consulted at all.
  int consentReads = 0;
  int consentWrites = 0;

  void _checkOnline() {
    if (offline != null) throw offline!;
  }

  @override
  Future<void> saveConsent(ConsentState value) async {
    _checkOnline();
    consentWrites++;
    consent = value;
  }

  @override
  Future<ConsentState?> getConsent() async {
    _checkOnline();
    consentReads++;
    return consent;
  }

  @override
  Future<void> saveOwnerProfile(OwnerProfile profile) async {
    _checkOnline();
    owner = profile;
  }

  @override
  Future<OwnerProfile?> getOwnerProfile() async {
    _checkOnline();
    return owner;
  }

  @override
  Future<void> savePet(PetInfo pet) async {
    _checkOnline();
    pets = [
      ...pets.where((p) => p.id != pet.id),
      pet,
    ];
  }

  @override
  Future<List<PetInfo>> getPets() async {
    _checkOnline();
    return [...pets];
  }

  @override
  Future<void> deletePet(String petId) async {
    _checkOnline();
    pets.removeWhere((p) => p.id == petId);
    assessments.remove(petId);
  }

  /// Everything the account owned, gone — the same cascade the real service
  /// performs, so a test can assert on what survives rather than on which
  /// calls were made.
  @override
  Future<void> deleteAllUserData() async {
    _checkOnline();
    userDataDeletions++;
    for (final pet in [...pets]) {
      await deletePet(pet.id);
    }
    consent = null;
    owner = null;
  }

  /// How many times the account's data was deleted, so a test can prove the
  /// cascade ran exactly once.
  int userDataDeletions = 0;

  @override
  Future<void> saveAssessment(String petId, ScoreResult result) async {
    _checkOnline();
    assessments.putIfAbsent(petId, () => []).insert(0, result);
  }

  @override
  Future<List<ScoreResult>> getAssessments(String petId) async {
    _checkOnline();
    return [...?assessments[petId]];
  }

  @override
  Future<Map<String, List<ScoreResult>>> getAllAssessments() async {
    _checkOnline();
    return {for (final e in assessments.entries) e.key: [...e.value]};
  }

  @override
  Future<List<Product>> getProducts() async => const [];
}
