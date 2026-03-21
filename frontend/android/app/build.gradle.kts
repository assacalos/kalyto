import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

val localProperties = Properties()
localProperties.load(FileInputStream(rootProject.file("key.properties")))

val flutter_key_storeFile = localProperties.getProperty("storeFile")
val flutter_key_storePassword = localProperties.getProperty("storePassword")
val flutter_key_keyAlias = localProperties.getProperty("keyAlias")
val flutter_key_keyPassword = localProperties.getProperty("keyPassword")

android {
    namespace = "com.easyconnect.app"
    compileSdk = 36  // requis par flutter_secure_storage 10+ et autres plugins
    ndkVersion = "28.2.13676358"

    signingConfigs {
        create("release") {
            storeFile = file(flutter_key_storeFile)
            storePassword = flutter_key_storePassword
            keyAlias = flutter_key_keyAlias
            keyPassword = flutter_key_keyPassword
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        // Activer le core library desugaring pour flutter_local_notifications
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.easyconnect.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 24  // Android 7.0 - requis par flutter_secure_storage 10+
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // Support de toutes les architectures CPU pour compatibilité maximale
        ndk {
            abiFilters.addAll(listOf("armeabi-v7a", "arm64-v8a", "x86", "x86_64"))
        }
    }

    // Configuration des splits ABI pour créer un APK universel
    splits {
        abi {
            isEnable = false  // Désactivé pour créer un APK universel (fat APK)
            reset()
            // Si vous voulez créer des APK séparés par architecture, décommentez:
            // include("armeabi-v7a", "arm64-v8a", "x86", "x86_64")
            // isUniversalApk = true  // Crée aussi un APK universel
        }
    }

    buildTypes {
        release {
            // Configuration de signature temporairement désactivée pour les tests
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
        debug {
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

dependencies {
    // Core library desugaring pour flutter_local_notifications (requis >= 2.1.4)
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation(platform("com.google.firebase:firebase-bom:34.7.0"))
    implementation("com.google.firebase:firebase-messaging")
    implementation("com.google.firebase:firebase-analytics")
}

flutter {
    source = "../.."
}
