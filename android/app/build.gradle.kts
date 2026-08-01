plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.shedbook.shedbook"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // 13 §3.1. Not optional and not deferrable: without this pair the release
        // build fails at :app:checkReleaseAarMetadata with "Dependency
        // ':flutter_local_notifications' requires core library desugaring", so
        // there is no .aab for gate G0 to read. Landed at N02-T01 for that
        // reason; N31-T02 and N24-T06 verify it rather than add it.
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.shedbook.shedbook"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    // The version is decision-record §5's, via 13 §3.1 — flutter_local_notifications
    // 22.2.0's documented minimum. It contributes nothing to the merged manifest:
    // "desugar" appears zero times in docs/gates/manifest-merger-release-report.txt.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
