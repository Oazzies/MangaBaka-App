# Keep Flutter's embedding and generated plugin wiring intact.
-keep class io.flutter.embedding.android.FlutterActivity { *; }
-keep class io.flutter.embedding.engine.FlutterEngine { *; }
-keep class io.flutter.plugin.common.PluginRegistry { *; }
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }
-keep class dev.oazzies.mangabaka_app.MainActivity { *; }

# Android/Google libraries used by Flutter plugins.
-dontwarn com.google.android.gms.**
-dontwarn com.google.mlkit.**
