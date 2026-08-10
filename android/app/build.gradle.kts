import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Must come after the Android plugin; consumes google-services.json.
    id("com.google.gms.google-services")
    // Must come after google-services. Flutter enables R8 for every release
    // build, so the shipped bundle is always obfuscated. Without this plugin
    // the Crashlytics SDK still reports errors, but no mapping file is
    // uploaded and the native-side stack traces arrive unreadable.
    id("com.google.firebase.crashlytics")
}

// ─── Release signing ────────────────────────────────────────────────────────
// `key.properties` sits in `android/` and holds the upload-key credentials.
// Its `storeFile` is resolved against `rootProject.projectDir` (= `android/`),
// so a value like `upload-keystore.jks` points at `android/upload-keystore.jks`.
//
// The file is loaded conditionally so `flutter run` on a fresh clone (no
// key.properties yet) still works — debug signing is used as a fallback.
val keystorePropertiesFile: File = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        FileInputStream(keystorePropertiesFile).use { load(it) }
    }
}
val hasReleaseKeystore: Boolean = keystorePropertiesFile.exists() &&
    (keystoreProperties["storeFile"] as String?)?.isNotBlank() == true

android {
    // Kotlin/Java package that R and BuildConfig are generated under.
    // Kept keyword-free — the Play-facing identifier lives in applicationId
    // below and uses `.in` (which is a Kotlin reserved word we don't want
    // leaking into imports).
    namespace = "com.mypetfit"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // Google Play identifier. NEVER change this after publishing — every
        // future update must ship under the same applicationId, otherwise
        // Play treats it as a brand-new app.
        applicationId = "com.mypetfit.in"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (hasReleaseKeystore) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = rootProject.file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // If a keystore is available (production build machine), use it.
            // Otherwise fall back to debug signing so local `flutter run
            // --release` continues to work without the keystore installed.
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
