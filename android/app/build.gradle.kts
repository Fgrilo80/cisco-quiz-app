import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

fun signingValue(propertyName: String, envName: String): String? {
    val fromFile = keystoreProperties.getProperty(propertyName)?.trim()?.takeIf { it.isNotEmpty() }
    if (fromFile != null) {
        return fromFile
    }
    return System.getenv(envName)?.trim()?.takeIf { it.isNotEmpty() }
}

val releaseStorePassword = signingValue("storePassword", "ANDROID_KEYSTORE_PASSWORD")
val releaseKeyPassword = signingValue("keyPassword", "ANDROID_KEY_PASSWORD")
val releaseKeyAlias = signingValue("keyAlias", "ANDROID_KEY_ALIAS")
val releaseStoreFilePath = signingValue("storeFile", "ANDROID_KEYSTORE_FILE")
val hasReleaseKeystore =
    listOf(releaseStorePassword, releaseKeyPassword, releaseKeyAlias, releaseStoreFilePath)
        .all { it != null }

val resolvedReleaseStore =
    if (hasReleaseKeystore) {
        val path = releaseStoreFilePath!!
        val fromAndroidDir = rootProject.file(path)
        val fromAppDir = file(path)
        when {
            fromAndroidDir.exists() -> fromAndroidDir
            fromAppDir.exists() -> fromAppDir
            else ->
                throw org.gradle.api.GradleException(
                    "Release keystore was configured but not found at ${fromAndroidDir.absolutePath} (also checked ${fromAppDir.absolutePath}).",
                )
        }
    } else {
        null
    }

val runningInCi = System.getenv("CI") == "true" || System.getenv("GITHUB_ACTIONS") == "true"

android {
    namespace = "pt.fgrilo.ciscoquiz.cisco_quiz"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "pt.fgrilo.ciscoquiz.cisco_quiz"
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
        if (resolvedReleaseStore != null) {
            create("release") {
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
                storePassword = releaseStorePassword
                storeFile = resolvedReleaseStore
            }
        }
    }

    buildTypes {
        release {
            // Release key when android/key.properties or ANDROID_KEYSTORE_* env vars exist
            // (GitHub Actions writes key.properties from secrets). Local builds without a
            // key still use the debug certificate so `flutter run --release` works.
            signingConfig =
                if (resolvedReleaseStore != null) {
                    signingConfigs.getByName("release")
                } else if (runningInCi) {
                    throw org.gradle.api.GradleException(
                        "CI release builds require a release keystore. " +
                            "Set GitHub Actions secrets ANDROID_KEYSTORE_BASE64, " +
                            "ANDROID_KEYSTORE_PASSWORD, ANDROID_KEY_PASSWORD and ANDROID_KEY_ALIAS, " +
                            "or provide android/key.properties (storeFile, storePassword, keyAlias, keyPassword).",
                    )
                } else {
                    signingConfigs.getByName("debug")
                }
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
