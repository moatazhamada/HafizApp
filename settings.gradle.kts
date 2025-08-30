pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
    plugins {
        id("org.jetbrains.kotlin.multiplatform") version "2.0.20"
        id("org.jetbrains.kotlin.android") version "2.0.20"
        id("org.jetbrains.kotlin.plugin.serialization") version "2.0.20"
        id("org.jetbrains.kotlin.plugin.compose") version "2.0.20"
        id("com.android.application") version "8.5.2"
        id("com.android.library") version "8.5.2"
        id("org.jetbrains.compose") version "1.7.0"
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "hafiz-kmp"
include(":shared")
include(":androidApp")
include(":composeApp")
