# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep native methods
-keepclassmembers class * {
    native <methods>;
}

# Keep Parcelable implementations
-keep class * implements android.os.Parcelable {
  public static final android.os.Parcelable$Creator *;
}

# Keep Serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep annotations
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Keep line numbers for debugging
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Isar Database
-keep class io.isar.** { *; }
-keep @io.isar.annotation.Collection class * { *; }

# GetX
-keep class com.get.** { *; }
-keepclassmembers class * extends com.get.GetxController {
    <methods>;
}

# Cryptography
-keep class com.google.crypto.** { *; }
-keep class org.bouncycastle.** { *; }

# Local Auth
-keep class io.flutter.plugins.localauth.** { *; }

# Secure Storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# Path Provider
-keep class io.flutter.plugins.pathprovider.** { *; }

# Google Fonts
-keep class com.google.fonts.** { *; }

# Desugaring - critical for R8 with coreLibraryDesugaring
-keep class j$.** { *; }
-keep class java.time.** { *; }
-dontwarn j$.**
-dontwarn java.time.**

# Suppress warnings from plugins that cause R8 to fail
-dontwarn com.google.errorprone.annotations.**
-dontwarn javax.annotation.**
-dontwarn kotlin.reflect.jvm.internal.**
-dontwarn org.codehaus.mojo.animal_sniffer.**
-dontwarn org.bouncycastle.**
-dontwarn com.google.crypto.tink.**
-dontwarn javax.naming.**
-dontwarn sun.security.**
-dontwarn com.sun.jna.**
-dontwarn okio.**
-dontwarn retrofit2.**
-dontwarn org.conscrypt.**

# Remove logging in release
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}
