# Flutter wraps its own engine rules; these cover the plugins this app uses.

# speech_to_text and flutter_tts resolve platform services reflectively.
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Keep annotated Flutter plugin entry points.
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.plugins.** { *; }

# Play Core is referenced by Flutter's deferred-components support, which this
# app does not use; without this, R8 fails on the missing classes.
-dontwarn com.google.android.play.core.**
