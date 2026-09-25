plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "dev.oazzies.mangabaka_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }


    defaultConfig {
        applicationId = "dev.oazzies.mangabaka_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["appAuthRedirectScheme"] = "dev.oazzies.mangabaka-app"
    }

    // A release build must be signed with the upload key. Falling back to the
    // debug key silently used to produce "release" APKs that no properly
    // signed update can ever install over (Android rejects a signature
    // change), stranding whoever installed one. So without the key the
    // release build fails, unless a local build opts in to debug signing
    // with MANGABAKA_ALLOW_DEBUG_SIGNING=true (never set this in CI).
    val releaseKeystorePath = System.getenv("ANDROID_KEYSTORE_PATH")
    val allowDebugSigning = System.getenv("MANGABAKA_ALLOW_DEBUG_SIGNING") == "true"

    signingConfigs {
        create("release") {
            if (!releaseKeystorePath.isNullOrEmpty()) {
                storeFile = file(releaseKeystorePath)
                storePassword = System.getenv("ANDROID_KEYSTORE_PASSWORD")
                keyAlias = System.getenv("ANDROID_KEY_ALIAS")
                keyPassword = System.getenv("ANDROID_KEY_PASSWORD")
            } else if (allowDebugSigning) {
                val debugConfig = signingConfigs.getByName("debug")
                storeFile = debugConfig.storeFile
                storePassword = debugConfig.storePassword
                keyAlias = debugConfig.keyAlias
                keyPassword = debugConfig.keyPassword
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

flutter {
    source = "../.."
}

// Fails a release build without the upload key up front, with an actionable
// message (AGP would otherwise stop at packaging with "SigningConfig release
// is missing required property storeFile").
gradle.taskGraph.whenReady {
    val buildsRelease = allTasks.any { it.project == project && it.name.contains("Release") }
    if (!buildsRelease) return@whenReady

    val keystorePath = System.getenv("ANDROID_KEYSTORE_PATH")
    if (keystorePath.isNullOrEmpty()) {
        if (System.getenv("MANGABAKA_ALLOW_DEBUG_SIGNING") == "true") return@whenReady
        throw GradleException(
            "Release signing key not configured: set ANDROID_KEYSTORE_PATH, " +
                "ANDROID_KEYSTORE_PASSWORD, ANDROID_KEY_ALIAS and ANDROID_KEY_PASSWORD. " +
                "For a local test build only, set MANGABAKA_ALLOW_DEBUG_SIGNING=true " +
                "(the result must never be distributed).",
        )
    }
    val required = listOf("ANDROID_KEYSTORE_PASSWORD", "ANDROID_KEY_ALIAS", "ANDROID_KEY_PASSWORD")
    val missing = required.filter { System.getenv(it).isNullOrEmpty() }
    if (missing.isNotEmpty()) {
        throw GradleException("ANDROID_KEYSTORE_PATH is set but $missing are not.")
    }
}

kotlin {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11)
    }
}
