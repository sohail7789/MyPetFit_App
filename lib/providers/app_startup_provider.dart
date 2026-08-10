import 'package:flutter/foundation.dart';

import '../providers/address_provider.dart';
import '../providers/pet_info_provider.dart';
import '../providers/quiz_provider.dart';

enum StartupStage {
  /// Nothing restored yet. The state a signed-out app sits in, and the one
  /// [reset] returns to so the next account starts clean.
  idle,

  loading,

  ready,

  /// Firestore could not be reached. Distinct from [loading] so the router
  /// stops waiting and the user is offered a retry instead of a spinner
  /// that never resolves.
  failed,
}

/// Single coordinator for restoring cloud state after authentication.
///
/// Owns the order — the local cache, then consent, owner, pets and
/// assessments — and the fact that it has happened. Nothing else should load
/// those: a screen that does its own loading and then navigates is what
/// produced the duplicate navigation this replaces.
///
/// The router treats [StartupStage.ready] as "everything `landingFor` reads
/// is now true of this account", so anything the landing decision depends on
/// has to be restored here, before the stage flips.
class AppStartupProvider extends ChangeNotifier {
  StartupStage _stage = StartupStage.idle;
  Object? _error;

  StartupStage get stage => _stage;

  /// What went wrong, when [stage] is [StartupStage.failed].
  Object? get error => _error;

  bool get isLoading => _stage == StartupStage.loading;

  bool get isReady => _stage == StartupStage.ready;

  bool get hasFailed => _stage == StartupStage.failed;

  /// Restores the signed-in user's data.
  ///
  /// Re-entrant by design: the router can land on the startup screen more
  /// than once for a single sign-in, and only the first call should do the
  /// work. A previous failure does not block a retry — only an in-flight or
  /// completed load does.
  /// [address] is optional so the many tests that only care about pets and
  /// assessments need not stand one up. Production always passes it — the
  /// delivery address is account state and has to be restored with the rest.
  Future<void> initialize({
    required PetInfoProvider petInfo,
    required QuizProvider quiz,
    AddressProvider? address,
  }) async {
    if (_stage == StartupStage.loading || _stage == StartupStage.ready) {
      return;
    }

    _stage = StartupStage.loading;
    _error = null;
    notifyListeners();

    try {
      // The local cache first, and awaited. main() only kicks those reads
      // off, so on a cold launch a reconciler could otherwise beat the
      // SharedPreferences read to the provider — and since each reconciler
      // persists the whole snapshot, that wrote `consentGiven: false` over a
      // stored `true`. Both calls are idempotent, so this is free once the
      // reads have already landed.
      await petInfo.init();
      await quiz.init();

      // Consent leads because the router's first gate is consent. It is
      // account state, not device state: without restoring it here, a
      // returning user arrived with their owner and pets in hand and was
      // still sent back to the consent screen.
      await petInfo.loadConsentFromFirestore();
      await petInfo.loadOwnerFromFirestore();
      await petInfo.loadPetsFromFirestore();
      await quiz.loadAssessmentsFromFirestore();
      // The delivery address belongs to the account, so it is restored here
      // with everything else that does. main() also reads it at launch, but
      // that read happens before there is a session — it can only reach the
      // device cache, and on a handset that has just signed in there is
      // nothing in it. Without this second read the account's saved address
      // stayed in Firestore and the profile offered to add one.
      await address?.init();
      _stage = StartupStage.ready;
    } catch (error, stack) {
      // Without this the throw escaped and left the stage on `loading`
      // forever, and the router — which waits on that stage — froze the app
      // on whatever screen it was showing.
      _error = error;
      _stage = StartupStage.failed;
      if (kDebugMode) {
        debugPrint('Startup failed: $error');
        debugPrintStack(stackTrace: stack);
      }
    }

    notifyListeners();
  }

  /// Returns to [StartupStage.idle].
  ///
  /// Must be called on sign-out. [initialize] refuses to run again once
  /// ready, so without this the next person to sign in on the device
  /// inherits the previous account's "already loaded" verdict and none of
  /// their own data is ever fetched.
  void reset() {
    _stage = StartupStage.idle;
    _error = null;
    notifyListeners();
  }
}
