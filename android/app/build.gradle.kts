import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android/Kotlin tooling.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing credentials, kept OUT of version control.
// Create android/key.properties from android/key.properties.example — see the
// "Build de release" section of the README for the keytool command.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        keystorePropertiesFile.inputStream().use { load(it) }
    }
}
val hasReleaseKeystore = keystoreProperties.getProperty("storeFile") != null

// CI still needs to compile a release AAB from a clean clone, but a developer
// must never accidentally publish a release signed with the debug key. The
// bypass is therefore opt-in and set only by our GitHub Actions validation job.
val allowDebugSignedRelease =
    System.getenv("CINEUS_ALLOW_DEBUG_SIGNED_RELEASE")?.equals("true", ignoreCase = true) == true

android {
    namespace = "dev.cineus.cineus"

    // Flutter 3.47.2 is CI-tested against Android API 36. Keep these explicit so
    // store compliance does not silently regress if a local Flutter SDK differs.
    compileSdk = 36
    ndkVersion = "28.2.13676358"

    compileOptions {
        // flutter_local_notifications uses Java APIs that require desugaring on
        // Android versions below their native availability.
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "dev.cineus.cineus"
        // Flutter 3.47 supports Android 24+ and Google Play requires target 36
        // for new apps/updates as of the 2026 release window.
        minSdk = 24
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = when {
                hasReleaseKeystore -> signingConfigs.getByName("release")
                allowDebugSignedRelease -> {
                    logger.warn(
                        "CI ONLY: release validation build is using the DEBUG key. " +
                            "This artifact must never be published."
                    )
                    signingConfigs.getByName("debug")
                }
                else -> throw GradleException(
                    "Release signing credentials are missing. Create android/key.properties " +
                        "from android/key.properties.example. Debug-signed release artifacts " +
                        "are blocked outside the explicit CI validation path."
                )
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
