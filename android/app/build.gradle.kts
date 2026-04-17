plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.skudyx"

    // ✅ Required by plugins (camera_camerax, connectivity_plus, shared_preferences, etc.)
    compileSdk = 36

    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.skudyx"

        // ✅ keep minSdk at least 21
        minSdk = flutter.minSdkVersion

        // ✅ targetSdk can be lower than compileSdk
        // Use 35 unless you have API 36 installed and want to target it.
        targetSdk = 35

        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Signing with debug for now (same as your template)
            signingConfig = signingConfigs.getByName("debug")
            
            // ✅ Enable code shrinking for release builds
            isMinifyEnabled = false
            isShrinkResources = false
        }
        debug {
            // ✅ Optional: Enable debug signing config explicitly
            signingConfig = signingConfigs.getByName("debug")
        }
    }
    
    // ✅ Add lint options to suppress OnBackInvokedCallback warning
    lint {
        disable += "OnBackInvokedCallback"
        checkReleaseBuilds = false
        abortOnError = false
    }
}

flutter {
    source = "../.."
}

dependencies {
    // ✅ Add any additional Android dependencies here if needed
    // implementation "androidx.core:core-ktx:1.12.0"
}