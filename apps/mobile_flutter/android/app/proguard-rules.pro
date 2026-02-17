# Keep source/line mapping for crash reports.
-renamesourcefileattribute SourceFile
-keepattributes SourceFile,LineNumberTable

# Keep Flutter engine/plugin entry points.
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Flutter references Play Core deferred-components classes even when not used.
# Allow shrinking without bundling deprecated Play Core 1.x.
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.splitinstall.model.**
-dontwarn com.google.android.play.core.tasks.**

# --- flutter_local_notifications: Gson TypeToken fix ---
# The plugin uses Gson internally to serialize scheduled notifications.
# R8 strips generic type signatures from TypeToken, causing a crash:
#   "TypeToken must be created with a type argument"
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keepattributes Signature

# Keep the notification plugin's serialization classes.
-keep class com.dexterous.flutterlocalnotifications.** { *; }
