# ProGuard/R8 rules for HafizApp release builds
# These rules prevent stripping of classes accessed via reflection

# ── Hive ──────────────────────────────────────────────
# Hive uses reflection for @HiveType adapters and generated .g.dart classes
-keep class * extends com.google.gson.TypeAdapterFactory { *; }
-keep class io.hive.** { *; }
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}
# Keep all Hive TypeAdapters and their generated code
-keep class **_hive_adapter { *; }
-keep class **.adapter.** { *; }
-keep class * implements com.google.gson.TypeAdapter { *; }
-keepattributes *Annotation*

# ── just_audio ────────────────────────────────────────
-keep class com.ryanheise.audioservice.** { *; }

# ── flutter_sound ─────────────────────────────────────
-keep class com.dooboolab.audioplayers.** { *; }

# ── flutter_appauth ───────────────────────────────────
-keep class net.openid.appauth.** { *; }

# ── Flutter/BLoC ──────────────────────────────────────
# Flutter engine handles its ownkeep rules via embedding
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# ── Firebase ──────────────────────────────────────────
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.internal.** { *; }
-dontwarn com.google.firebase.**

# ── Dio ───────────────────────────────────────────────
# Dio interceptors may be accessed reflectively
-keep class * extends com.squareup.okhttp3.Interceptor { *; }

# ── General Flutter safety ────────────────────────────
# Keep all serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    !static !transient <fields>;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Preserve line numbers for crash reports
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
