# ═══════════════════════════════════════════════════════════════════════════
# YouMe — ProGuard / R8 Rules
# Applied to release builds only (minifyEnabled true in build.gradle)
# ═══════════════════════════════════════════════════════════════════════════

# ── Flutter engine ──────────────────────────────────────────────────────────
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.view.** { *; }
-dontwarn io.flutter.**

# ── Kotlin ──────────────────────────────────────────────────────────────────
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception

# ── AndroidX ────────────────────────────────────────────────────────────────
-keep class androidx.lifecycle.** { *; }
-keep class androidx.core.app.** { *; }
-dontwarn androidx.**

# ── Firebase / FCM ──────────────────────────────────────────────────────────
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# ── Supabase / OkHttp / Ktor ────────────────────────────────────────────────
-keep class io.github.jan.supabase.** { *; }
-keep class io.ktor.** { *; }
-keep class okhttp3.** { *; }
-keep class okio.** { *; }
-dontwarn io.ktor.**
-dontwarn okhttp3.**
-dontwarn okio.**

# ── Remove all logging in release ───────────────────────────────────────────
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int i(...);
    public static int w(...);
    public static int d(...);
    public static int e(...);
}

# Remove System.out.println
-assumenosideeffects class java.io.PrintStream {
    public void println(...);
    public void print(...);
}

# ── Encryption / Security ───────────────────────────────────────────────────
-keep class javax.crypto.** { *; }
-keep class java.security.** { *; }
-keep class org.bouncycastle.** { *; }
-dontwarn org.bouncycastle.**

# ── Google Maps ─────────────────────────────────────────────────────────────
-keep class com.google.maps.** { *; }
-dontwarn com.google.maps.**

# ── Serialization (JSON) ─────────────────────────────────────────────────────
-keepattributes Signature
-keepattributes Exceptions
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# ── General Android app ─────────────────────────────────────────────────────
-keep public class * extends android.app.Activity
-keep public class * extends android.app.Application
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.content.ContentProvider
-keep public class * extends android.app.backup.BackupAgentHelper
-keep public class * extends android.preference.Preference

# ── Parcelable ──────────────────────────────────────────────────────────────
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}
-keepclassmembers class * implements android.os.Parcelable {
    static ** CREATOR;
}

# ── Enum ────────────────────────────────────────────────────────────────────
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# ── Remove debug symbols ─────────────────────────────────────────────────────
-optimizationpasses 5
-dontusemixedcaseclassnames
-verbose

# ── Security: obfuscate everything not explicitly kept ───────────────────────
-repackageclasses 'com.youme.obf'
-allowaccessmodification
-mergeinterfacesaggressively

# ── Prevent reflection-based attacks ────────────────────────────────────────
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}
