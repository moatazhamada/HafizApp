# ProGuard/R8 rules for HafizApp release builds
# These rules prevent stripping of classes accessed via reflection or JNI
# from Flutter plugins and native libraries.

# ── General keep attributes ───────────────────────────
# Preserve annotations, signatures, and inner classes used by reflection
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod
-keepattributes RuntimeVisibleAnnotations
-keepattributes RuntimeVisibleParameterAnnotations
-keepattributes RuntimeVisibleFieldAnnotations

# Preserve line numbers for Firebase Crashlytics and deobfuscation
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# ── Flutter Framework ─────────────────────────────────
# Flutter engine and plugin registrars use reflection
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# ── Firebase (Crashlytics, Analytics, Remote Config) ──
# Firebase SDKs ship their own consumer ProGuard rules, but we keep
# broad signatures to avoid aggressive obfuscation of crash traces.
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.internal.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.internal.**

# ── Dio / JSON Serialization ──────────────────────────
# Dio is pure Dart; no native Android ProGuard rules are required.
# All Dart models are AOT-compiled and not processed by R8.
# If any native OkHttp/cronet HTTP engine is added later, add
# its rules here.

# ── Hive ──────────────────────────────────────────────
# Hive is a pure Dart package. Generated adapters live in Dart code
# and are compiled via AOT; they are not affected by Android ProGuard.
# No native Android keep rules are required for Hive itself.

# ── just_audio ────────────────────────────────────────
-keep class com.ryanheise.just_audio.** { *; }

# ── audio_session ─────────────────────────────────────
-keep class com.ryanheise.audio_session.** { *; }

# ── flutter_sound ─────────────────────────────────────
-keep class xyz.canardoux.fluttersound.** { *; }

# ── speech_to_text ────────────────────────────────────
-keep class com.csdcorp.speech_to_text.** { *; }

# ── whisper_ggml_plus ─────────────────────────────────
-keep class com.devac.whisper_ggml_plus.** { *; }

# ── flutter_appauth / AppAuth-Android ─────────────────
-keep class net.openid.appauth.** { *; }
-keep class net.openid.appauth.browser.** { *; }
-dontwarn net.openid.appauth.**

# ── flutter_local_notifications ───────────────────────
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# ── home_widget ───────────────────────────────────────
-keep class es.antonborri.home_widget.** { *; }
# If the app defines a custom AppWidgetProvider, keep it explicitly.
# Update the fully-qualified class name if it changes.
-keep class com.hafiz.app.hafiz_app.HafizAppWidgetProvider { *; }

# ── connectivity_plus ─────────────────────────────────
-keep class dev.fluttercommunity.plus.connectivity.** { *; }

# ── flutter_secure_storage ────────────────────────────
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# ── share_plus ────────────────────────────────────────
-keep class dev.fluttercommunity.plus.share.** { *; }

# ── permission_handler ────────────────────────────────
-keep class com.baseflow.permissionhandler.** { *; }

# ── url_launcher ──────────────────────────────────────
-keep class io.flutter.plugins.urllauncher.** { *; }

# ── package_info_plus ─────────────────────────────────
-keep class dev.fluttercommunity.plus.packageinfo.** { *; }

# ── wakelock_plus ─────────────────────────────────────
-keep class dev.fluttercommunity.plus.wakelock.** { *; }

# ── in_app_review ─────────────────────────────────────
-keep class dev.britannio.in_app_review.** { *; }

# ── path_provider ─────────────────────────────────────
-keep class io.flutter.plugins.pathprovider.** { *; }

# ── sqflite (transitive via flutter_cache_manager) ────
-keep class com.tekartik.sqflite.** { *; }

# ── Play Core / In-app updates (if used transitively) ─
-dontwarn com.google.android.play.core.**

# ── Serializable safety net ───────────────────────────
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    !static !transient <fields>;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}
