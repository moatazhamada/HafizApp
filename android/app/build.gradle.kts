import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    id("com.google.firebase.firebase-perf")
}

android {
    namespace = "com.hafiz.app.hafiz_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "29.0.13113456"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
    }

    kotlinOptions {
        jvmTarget = "21"
    }

    defaultConfig {
        applicationId = "com.hafiz.app.hafiz_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    signingConfigs {
        create("release") {
            // Try environment variables first (for CI/CD), then fall back to keystore.properties
            val envKeyAlias = System.getenv("KEY_ALIAS")
            val envKeyPassword = System.getenv("KEY_PASSWORD")
            val envStorePassword = System.getenv("KEYSTORE_PASSWORD")
            val envStoreFile = System.getenv("KEYSTORE_FILE")
            
            if (envKeyAlias != null && envKeyPassword != null && envStorePassword != null) {
                // Use environment variables for CI/CD
                keyAlias = envKeyAlias
                keyPassword = envKeyPassword
                storePassword = envStorePassword
                storeFile = if (envStoreFile != null) file(envStoreFile) else file("app/keystore.jks")
            } else {
                // Fall back to keystore.properties for local builds
                val keystoreProperties = Properties()
                val keystorePropertiesFile = rootProject.file("keystore.properties")
                if (keystorePropertiesFile.exists()) {
                    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
                }

                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                if (keystoreProperties.getProperty("storeFile") != null) {
                    storeFile = file(keystoreProperties.getProperty("storeFile"))
                }
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            // Check if release signing config has the necessary properties
            val config = signingConfigs.getByName("release")
            if (config.keyAlias != null && config.keyPassword != null && config.storeFile != null && config.storePassword != null) {
                signingConfig = config
            } else {
                signingConfig = signingConfigs.getByName("debug")
            }
        }
    }
    
    // Support 16 KB page sizes for Android 15+
    packagingOptions {
        jniLibs {
            useLegacyPackaging = true
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.multidex:multidex:2.0.1")
    implementation("com.google.android.material:material:1.12.0")
}
