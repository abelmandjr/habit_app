import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Chave de release própria (tarefa 2.10). O key.properties e a chave ficam
// fora do Git; ver android/ASSINATURA.md.
val keyProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}
val hasReleaseKey = keyProperties.getProperty("storeFile") != null

android {
    namespace = "com.abelmandjr.habitapp"

    compileSdk = flutter.compileSdkVersion

    defaultConfig {
        applicationId = "com.abelmandjr.habitapp"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["appLabel"] = "Hábitos"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
        isCoreLibraryDesugaringEnabled = true
    }

    signingConfigs {
        if (hasReleaseKey) {
            create("release") {
                storeFile = file(keyProperties.getProperty("storeFile"))
                storePassword = keyProperties.getProperty("storePassword")
                keyAlias = keyProperties.getProperty("keyAlias")
                keyPassword = keyProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        // A app de debug (com.abelmandjr.habitapp.debug) convive no telemóvel
        // com a de release (com.abelmandjr.habitapp).
        debug {
            applicationIdSuffix = ".debug"
            manifestPlaceholders["appLabel"] = "Hábitos (debug)"
        }
        release {
            // Sem key.properties (ex.: um clone do repositório), o release é
            // assinado com a chave de debug e não serve para distribuir.
            signingConfig = if (hasReleaseKey) {
                signingConfigs.getByName("release")
            } else {
                logger.warn("key.properties não encontrado: release assinado com a chave de debug.")
                signingConfigs.getByName("debug")
            }
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
