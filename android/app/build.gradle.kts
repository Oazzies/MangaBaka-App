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

    // Debug-signed "release" APKs can never be updated by a signed build, stranding users.
    // MANGABAKA_ALLOW_DEBUG_SIGNING=true is for local test builds only, never CI.
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

    // Google Play policy: store builds drop REQUEST_INSTALL_PACKAGES from the manifest.
    val isStoreBuild =
        System.getenv("STORE_BUILD") == "true" || project.hasProperty("storeBuild")
    if (isStoreBuild) {
        sourceSets.getByName("release").manifest.srcFile("src/play/AndroidManifest.xml")
    }
}

flutter {
    source = "../.."
}

// Fails early; AGP would otherwise stop at packaging with an unhelpful storeFile error.
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
