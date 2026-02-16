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
