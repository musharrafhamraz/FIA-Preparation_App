## Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

## HTTP and networking
-keep class java.net.** { *; }
-keep class javax.net.ssl.** { *; }
-keep class org.apache.http.** { *; }
-keep interface org.apache.http.** { *; }

## SharedPreferences
-keep class android.content.SharedPreferences { *; }
-keep class android.content.SharedPreferences$** { *; }

## Keep JSON classes for parsing
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.** { *; }

## Dart/Flutter specific
-dontwarn io.flutter.embedding.**
-dontwarn io.flutter.**

## Keep native methods
-keepclasseswithmembers class * {
    native <methods>;
}