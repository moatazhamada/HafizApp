plugins {
    kotlin("multiplatform")
    id("com.android.library")
}

kotlin {
    androidTarget()

    sourceSets {
        val commonMain by getting {
            dependencies {
                // Add common dependencies here if needed
            }
        }
        val commonTest by getting

        val androidMain by getting
        val androidUnitTest by getting
    }
}

android {
    namespace = "com.hafiz.kmp.shared"
    compileSdk = 34

    defaultConfig {
        minSdk = 24
    }
    sourceSets["main"].manifest.srcFile("src/androidMain/AndroidManifest.xml")
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}
