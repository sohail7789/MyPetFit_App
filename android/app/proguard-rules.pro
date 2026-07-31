# Flutter needs its embedding classes to stay unshrunk.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Play Core split-install (referenced by Flutter's deferred components glue
# even when you don't use deferred components). Suppress missing-class errors.
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# Kotlin metadata used by reflection in some plugins.
-keep class kotlin.Metadata { *; }
-keepattributes *Annotation*, InnerClasses, EnclosingMethod, Signature
