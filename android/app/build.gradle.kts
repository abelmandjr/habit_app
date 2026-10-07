plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.habit_app"

    compileSdk = flutter.compileSdkVersion

    defaultConfig {
        applicationId = "com.example.habit_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["appLabel"] = "habit_app"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
        isCoreLibraryDesugaringEnabled = true
    }

    buildTypes {
        // A app de debug (com.example.habit_app.debug) convive no telemóvel
        // com a de release (com.example.habit_app).
        debug {
            applicationIdSuffix = ".debug"
            manifestPlaceholders["appLabel"] = "habit_app (debug)"
        }
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}


dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

kotlin {
    jvmToolchain(21)
}



flutter {
    source = "../.."
}
