plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.io.FileInputStream
import java.util.Properties

// Release signing follows the official Flutter deployment guide:
// a local key.properties (gitignored, see key.properties.example) feeds a
// `release` signing config with the Receipts upload keystore
// (alias receipts-upload). Release builds fail fast with a clear error when
// the file is missing instead of silently shipping a debug-signed build.
// See: https://docs.flutter.dev/deployment/android#signing-the-app
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

val isReleaseBuild = gradle.startParameter.taskNames.any {
    it.contains("Release", ignoreCase = true)
}
if (isReleaseBuild && !keystorePropertiesFile.exists()) {
    throw GradleException(
        "Release signing requires android/key.properties with " +
            "storePassword, keyPassword, keyAlias and storeFile. " +
            "Copy android/key.properties.example to get started. " +
            "The file is gitignored and must never be committed."
    )
}
for (key in listOf("storePassword", "keyPassword", "keyAlias", "storeFile")) {
    if (isReleaseBuild && !keystoreProperties.containsKey(key)) {
        throw GradleException(
            "android/key.properties is missing required key \"$key\". " +
                "See android/key.properties.example."
        )
    }
}

android {
    namespace = "com.receipts.receipts"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Required by flutter_local_notifications v10+ for scheduled
        // notifications with backwards compatibility.
        // See: https://pub.dev/packages/flutter_local_notifications#gradle-setup
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.receipts.receipts"
        // Required by flutter_local_notifications v10+ for scheduled
        // notifications (desugaring). See:
        // https://pub.dev/packages/flutter_local_notifications#gradle-setup
        multiDexEnabled = true
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Always the upload keystore. Missing credentials fail fast
            // above; debug keys are never used for release.
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    // Required by flutter_local_notifications v10+ (desugaring).
    // See: https://pub.dev/packages/flutter_local_notifications#gradle-setup
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
