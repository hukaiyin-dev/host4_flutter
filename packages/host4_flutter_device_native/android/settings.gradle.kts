pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("com.android.library") version "8.11.1" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)
    repositories {
        google()
        mavenCentral()

        val localProperties = java.util.Properties()
        val localPropertiesFile = file("local.properties")
        if (localPropertiesFile.exists()) {
            localPropertiesFile.inputStream().use { localProperties.load(it) }
        }
        val flutterSdkPath = localProperties.getProperty("flutter.sdk")
        if (flutterSdkPath != null) {
            val engineRealmFile = file("$flutterSdkPath/bin/cache/engine.realm")
            val engineRealm =
                if (engineRealmFile.exists()) engineRealmFile.readText().trim() else ""
            val storageUrl = System.getenv("FLUTTER_STORAGE_BASE_URL") ?: "https://storage.googleapis.com"
            val realmPrefix = if (engineRealm.isNotEmpty()) "$engineRealm/" else ""
            maven {
                url = uri("$storageUrl/${realmPrefix}download.flutter.io")
            }
        }
    }
}

rootProject.name = "host4_flutter_device_native"
