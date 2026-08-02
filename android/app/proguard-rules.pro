# Flutter engine + plugin bindings are invoked via reflection from generated
# GeneratedPluginRegistrant; R8 can't see those call sites, so keep them.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# sqflite opens the SQLite driver via JNI class lookup.
-keep class org.sqlite.** { *; }
-keep class org.sqlite.database.** { *; }

# Flutter's deferred-components path references Play Core split-install
# classes; this app doesn't ship dynamic feature modules, so they're absent
# from the classpath on purpose. Silence R8 instead of pulling in the dep.
-dontwarn com.google.android.play.core.**
