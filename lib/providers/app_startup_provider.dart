import 'package:flutter/foundation.dart';

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
/// Owns the order — owner, then pets, then assessments — and the fact that
/// it has happened. Nothing else should load those three: a screen that does
/// its own loading and then navigates is what produced the duplicate
/// navigation this replaces.
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
  Future<void> initialize({
    required PetInfoProvider petInfo,
    required QuizProvider quiz,
  }) async {
    if (_stage == StartupStage.loading || _stage == StartupStage.ready) {
      return;
    }

    _stage = StartupStage.loading;
    _error = null;
    notifyListeners();

    try {
      await petInfo.loadOwnerFromFirestore();
      await petInfo.loadPetsFromFirestore();
      await quiz.loadAssessmentsFromFirestore();
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
