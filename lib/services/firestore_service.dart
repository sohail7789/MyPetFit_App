import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/owner_profile.dart';
import '../models/pet_info.dart';
import '../models/product.dart';
import '../models/score_result.dart';

/// Raised when a signed-in user is required and there isn't one.
///
/// Its own type so callers can tell it apart from a network failure: a
/// network failure is worth retrying, this never is. [CloudSync] discards
/// pending writes that raise it rather than replaying them, which is what
/// stops a write queued before sign-out landing under the next account.
class NotSignedInException implements Exception {
  const NotSignedInException();

  @override
  String toString() => 'NotSignedInException: no authenticated user';
}

class FirestoreService {
  // Resolved on first use rather than at construction. `.instance` throws if
  // Firebase has not been initialised, and as eager field initialisers that
  // made the service — and every provider holding one — impossible to
  // construct in a test. Production is unaffected: main() initialises
  // Firebase long before anything reads these.
  late final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final FirebaseAuth _auth = FirebaseAuth.instance;

  /// The signed-in user's id.
  ///
  /// Replaces `currentUser!` throughout. The bang threw a null-check error
  /// from deep inside a queued write when a sync drained just after
  /// sign-out — an unreadable crash for a condition that is entirely
  /// expected.
  String get _uid {
    final user = _auth.currentUser;
    if (user == null) throw const NotSignedInException();
    return user.uid;
  }

  Future<List<Product>> getProducts() async {
    final snapshot = await _firestore
        .collection('products')
        .where('active', isEqualTo: true)
        .get();

    return snapshot.docs
        .map(
          (doc) =>
          Product.fromMap(
            doc.id,
            doc.data(),
          ),
    )
        .toList();
  }

  /// Save owner profile of currently logged in user.
  Future<void> saveOwnerProfile(OwnerProfile profile,) async {
    final uid = _uid;

    await _firestore
        .collection('users')
        .doc(uid)
        .set(
      profile.toMap(),
      SetOptions(merge: true),
    );
  }

  /// Load owner profile of currently logged in user.
  Future<OwnerProfile?> getOwnerProfile() async {
    final uid = _uid;

    final doc = await _firestore
        .collection('users')
        .doc(uid)
        .get();

    if (!doc.exists) return null;

    final data = doc.data();

    if (data == null) return null;

    if (!data.containsKey('ownerName')) {
      return null;
    }

    return OwnerProfile.fromMap(data);
  }

  /// Save one pet for the currently logged in user.
  Future<void> savePet(PetInfo pet) async {
    final uid = _uid;

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('pets')
        .doc(pet.id)
        .set(
      pet.toJson(),
      SetOptions(merge: true),
    );
  }

  /// Load all pets of the currently logged in user.
  Future<List<PetInfo>> getPets() async {
    final uid = _uid;

    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('pets')
        .get();

    return snapshot.docs
        .map((doc) => PetInfo.fromJson(doc.data()))
        .toList();
  }

  /// Save one completed assessment for a pet.
  /// Writes an assessment and refreshes the pet's summary atomically.
  ///
  /// These were two sequential writes. Failing between them left the report
  /// stored but `latestScore` stale, so the dashboard disagreed with the
  /// report history until the next assessment happened to fix it. A batch
  /// commits both or neither.
  ///
  /// The document id is the completion time in millis — deterministic, so a
  /// retry overwrites its own earlier attempt instead of adding a duplicate.
  Future<void> saveAssessment(
    String petId,
    ScoreResult result,
  ) async {
    final uid = _uid;

    final petRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('pets')
        .doc(petId);

    final batch = _firestore.batch();

    batch.set(
      petRef
          .collection('assessments')
          .doc(result.completedAt.millisecondsSinceEpoch.toString()),
      result.toJson(),
    );

    batch.set(
      petRef,
      {
        'lastAssessmentAt': result.completedAt.toIso8601String(),
        'latestScore': result.percentageScore,
        'latestCategory': result.category.name,
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  /// Load all assessments for one pet.
  Future<List<ScoreResult>> getAssessments(String petId,) async {
    final uid = _uid;

    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('pets')
        .doc(petId)
        .collection('assessments')
        .orderBy('completedAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => ScoreResult.fromJson(doc.data()))
        .toList();
  }

  Future<Map<String, List<ScoreResult>>> getAllAssessments() async {
    final uid = _uid;

    final pets = await _firestore
        .collection('users')
        .doc(uid)
        .collection('pets')
        .get();

    final results = <String, List<ScoreResult>>{};

    for (final pet in pets.docs) {
      final assessments = await pet.reference
          .collection('assessments')
          .orderBy('completedAt', descending: true)
          .get();

      results[pet.id] = assessments.docs
          .map((doc) => ScoreResult.fromJson(doc.data()))
          .toList();
    }

    return results;
  }

  /// Deletes a pet and everything under it.
  ///
  /// Firestore does not cascade: deleting a document leaves its
  /// subcollections in place as orphans, still billed and still returned by
  /// a collection-group query. The assessments therefore have to go first,
  /// and the pet document last — the reverse would leave the assessments
  /// unreachable through the parent if the second delete failed.
  ///
  /// Batched so the assessments disappear together rather than one by one.
  /// A batch caps at 500 operations, so they are chunked; a pet is capped at
  /// [QuizProvider.maxHistory] reports in the app, but a document written by
  /// an older build or another client is not, so the loop is not optional.
  Future<void> deletePet(String petId) async {
    final uid = _uid;

    final petRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('pets')
        .doc(petId);

    final assessments = await petRef.collection('assessments').get();

    const chunkSize = 400; // headroom under Firestore's 500-op batch limit
    for (var i = 0; i < assessments.docs.length; i += chunkSize) {
      final batch = _firestore.batch();
      for (final doc in assessments.docs.skip(i).take(chunkSize)) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }

    await petRef.delete();
  }

}