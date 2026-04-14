import com.android.build.gradle.LibraryExtension

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

// Set namespaces and fix compileSdk for plugins that need it
// Using gradle.afterProject which fires after each project is evaluated
gradle.afterProject {
    if (plugins.hasPlugin("com.android.library")) {
        val android = extensions.getByType(LibraryExtension::class.java)

        // Force all library subprojects to compile against SDK 36
        // This fixes the "android:attr/lStar not found" error in older plugins like isar
        if (android.compileSdk == null || android.compileSdk!! < 36) {
            android.compileSdk = 36
        }

        // Set namespace for plugins that lack one
        if (android.namespace.isNullOrEmpty()) {
            val ns = when (name) {
                "isar_flutter_libs" -> "dev.isar.isar_flutter_libs"
                "screen_protector" -> "com.prongbang.screen_protector"
                "flutter_app_lock" -> "com.example.flutter_app_lock"
                "flutter_secure_storage" -> "com.it_nomads.fluttersecurestorage"
                "local_auth_android" -> "io.flutter.plugins.localauth"
                "file_picker" -> "com.mr.flutter.plugin.filepicker"
                "permission_handler_android" -> "com.baseflow.permissionhandler"
                "flutter_local_notifications" -> "com.dexterous.flutterlocalnotifications"
                "url_launcher_android" -> "io.flutter.plugins.urllauncher"
                "path_provider_android" -> "io.flutter.plugins.pathprovider"
                "shared_preferences_android" -> "io.flutter.plugins.sharedpreferences"
                else -> null
            }
            if (ns != null) {
                android.namespace = ns
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
