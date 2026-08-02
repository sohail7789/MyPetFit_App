/// Maps semantic asset roles to the filenames actually shipped in
/// `assets/v3/`.
///
/// The exported files are named by the screen they appear on rather than by
/// the design document's internal names, so this indirection keeps screen code
/// readable and means a re-export under different filenames is a one-file fix.
///
/// Anything still missing resolves to a path with no file on disk;
/// `DesignImage` renders its placeholder for those rather than throwing.
///
/// Filenames deliberately contain no spaces. Flutter's image loader tolerates
/// them, but video_player on Android resolves assets through ExoPlayer's
/// AssetDataSource, which fails with FileNotFoundException on any path
/// containing a space — so the videos silently fell back to their posters.
///
/// These are `const` so screens can stay in const constructors.
class AppAssets {
  AppAssets._();

  // -- Onboarding & auth (screens 01–09) --------------------------------

  /// Not yet supplied — the Welcome lockup falls back to a placeholder.
  static const String logo = 'assets/v3/logo.png';

  static const String welcomeVideo = 'assets/v3/welcome-screen-transparent.webm';
  static const String welcomePoster = 'assets/v3/running.png';

  /// Apple-compatible encodes (HEVC-with-alpha .mov, or .mp4 where
  /// transparency isn't needed). iOS cannot decode WebM, so these are what
  /// play there; until they exist the poster still is shown.
  static const String welcomeVideoApple = 'assets/v3/welcome-screen.mov';

  static const String onboarding1 = 'assets/v3/onboard-1.png';
  static const String onboarding2 = 'assets/v3/onboard-2.png';
  static const String onboarding3 = 'assets/v3/onboard-3.png';

  static const String signIn = 'assets/v3/sign-in.png';
  static const String signUp = 'assets/v3/sign-up.png';
  static const String forgotPassword = 'assets/v3/forgot-password.png';
  static const String verifyCode = 'assets/v3/verify-code.png';
  static const String resetPassword = 'assets/v3/reset-password.png';

  // -- Assessment (screens 10–23b) --------------------------------------

  static const String ownerDetails = 'assets/v3/owner-details.png';

  /// Still frame behind the scoring interstitial, and its motion version.
  static const String analyzing = 'assets/v3/analyzing.png';
  static const String scoringVideo = 'assets/v3/scoring-your-answers.webm';
  static const String scoringVideoApple = 'assets/v3/scoring-your-answers.mov';

  /// Report card celebration — motion plus the still it falls back to.
  static const String reportCardVideo = 'assets/v3/fitness-report-card.webm';
  static const String reportCardVideoApple = 'assets/v3/fitness-report-card.mov';
  static const String greatJob = 'assets/v3/great-job.png';

  /// Shown for the Critical band on screen 23b.
  static const String vetAlert = 'assets/v3/vet-alert.png';

  /// Lottie walker on the assessment progress track.
  static const String walker = 'assets/v3/dog_walking.json';

  // -- Shop (screens 24–29b) --------------------------------------------

  static const String orderPlaced = 'assets/v3/order-placed.png';
  static const String orderTracking = 'assets/v3/order-tracking.png';

  // -- Puppy expression set ---------------------------------------------

  /// Expressions reused outside the assessment: the "why it's picked" card,
  /// empty-cart and help states.
  static const String emoHappy = 'assets/v3/emo-happy.png';
  static const String emoTilt = 'assets/v3/emo-tilt.png';
  static const String emoQuestion = 'assets/v3/emo-question.png';
  static const String emoSleep = 'assets/v3/emo-sleep.png';

  /// One puppy expression per assessment category, in category order. The
  /// design pairs a specific mood with each category — keep this order:
  ///
  /// 1 Skin & Coat → happy          6 Digestive & Urinary → worried
  /// 2 Activity & Fitness → excited  7 Physical & Internal → determined
  /// 3 Oral/Vision/Hearing → surprised 8 Medical & Lifestyle → tilt
  /// 4 Behavior & Mental → thinking  9 Additional Info → question
  /// 5 Sleep & Nutrition → sleep
  ///
  /// Only `emo-happy.png` is present so far; the rest fall back to the
  /// placeholder until supplied.
  static const List<String> categoryFaces = [
    'assets/v3/emo-happy.png',
    'assets/v3/emo-excited.png',
    'assets/v3/emo-surprised.png',
    'assets/v3/emo-thinking.png',
    'assets/v3/emo-sleep.png',
    'assets/v3/emo-worried.png',
    'assets/v3/emo-determined.png',
    'assets/v3/emo-tilt.png',
    'assets/v3/emo-question.png',
  ];

  static String categoryFace(int index) =>
      categoryFaces[index.clamp(0, categoryFaces.length - 1)];
}
