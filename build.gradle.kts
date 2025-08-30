plugins {
    // empty; configuration lives in subprojects
}

allprojects {
    group = "com.hafiz.kmp"
    version = "0.1.0"
}

tasks.register("clean", Delete::class) {
    delete(rootProject.buildDir)
}

