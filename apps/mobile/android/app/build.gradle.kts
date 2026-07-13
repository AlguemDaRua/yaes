import java.io.FileInputStream
import java.util.Properties
import org.gradle.api.tasks.compile.JavaCompile

// Release signing: android/key.properties + the keystore are NOT in git.
// CI provides them from secrets; without them the build falls back to the
// debug key so local `flutter run --release` keeps working.
val keystoreProperties = Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.exists()) FileInputStream(f).use { load(it) }
}

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "mz.co.ya.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
          // habilita desugaring
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "mz.co.ya.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // Injected into AndroidManifest; override per-build with the
        // MAPBOX_TOKEN env var or -PMAPBOX_TOKEN=... (pk tokens are public
        // client tokens — restrict them by scope/URL in the Mapbox dashboard).
        manifestPlaceholders["MAPBOX_TOKEN"] =
            System.getenv("MAPBOX_TOKEN")
                ?: (project.findProperty("MAPBOX_TOKEN") as String?)
                ?: "pk.eyJ1IjoiYWRpbHNvbm11aWFuZ2EiLCJhIjoiY21nOGNnams3MDY5YzJsczc5cG4xZjFpdCJ9.oQK2hk0BJMYnaFWRjEmmXw"
    }

    signingConfigs {
        if (keystoreProperties.containsKey("storeFile")) {
            create("release") {
                storeFile =
                    file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig =
                if (keystoreProperties.containsKey("storeFile")) {
                    signingConfigs.getByName("release")
                } else {
                    signingConfigs.getByName("debug")
                }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android.txt"),
                "proguard-rules.pro"
            )
        }
    }


    // buildTypes {
    //     release {
    //         // TODO: Add your own signing config for the release build.
    //         // Signing with the debug keys for now, so `flutter run --release` works.
    //         signingConfig = signingConfigs.getByName("debug")
    //     }
    // }
}

// tasks.withType<JavaCompile> {     
//    options.compilerArgs.add("-Xlint:deprecation")
// }

flutter {
    source = "../.."
}

dependencies {
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk8:1.9.25")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}

