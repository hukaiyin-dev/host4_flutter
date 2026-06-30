import java.util.Properties

group = "com.host4.host4_flutter_device_native"
version = "1.0-SNAPSHOT"

plugins {
    id("com.android.library")
    id("org.jetbrains.kotlin.android")
}

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.inputStream().use { localProperties.load(it) }
}

val flutterSdkPath =
    localProperties.getProperty("flutter.sdk")
        ?: error(
            "flutter.sdk not set in local.properties. " +
                "Add flutter.sdk=/path/to/flutter (e.g. flutter.sdk=/opt/homebrew/share/flutter)",
        )
val engineVersion = file("$flutterSdkPath/bin/cache/engine.stamp").readText().trim()

android {
    namespace = "com.host4.host4_flutter_device_native"

    compileSdk = 36

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    sourceSets {
        getByName("main") {
            java.srcDirs("src/main/kotlin")
        }
        getByName("test") {
            java.srcDirs("src/test/kotlin")
        }
    }

    defaultConfig {
        minSdk = 24
    }

    testOptions {
        unitTests {
            isIncludeAndroidResources = true
            all {
                it.useJUnitPlatform()

                it.outputs.upToDateWhen { false }

                it.testLogging {
                    events("passed", "skipped", "failed", "standardOut", "standardError")
                    showStandardStreams = true
                }
            }
        }
    }
}

dependencies {
    implementation(fileTree(mapOf("dir" to "libs", "include" to listOf("*.jar"))))
    implementation("androidx.appcompat:appcompat:1.7.0")
    implementation("io.reactivex.rxjava2:rxandroid:2.1.1")
    implementation("io.reactivex.rxjava2:rxjava:2.2.21")
    implementation("com.polidea.rxandroidble2:rxandroidble:1.19.0")

    // Flutter embedding: normally injected by the Flutter app build; required when opening
    // this android/ folder standalone in Android Studio.
    compileOnly("io.flutter:flutter_embedding_debug:1.0.0-$engineVersion") {
        isTransitive = false
    }

    testImplementation("org.jetbrains.kotlin:kotlin-test")
    testImplementation("org.mockito:mockito-core:5.0.0")
    testImplementation("io.flutter:flutter_embedding_debug:1.0.0-$engineVersion") {
        isTransitive = false
    }
}
