plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("com.google.gms.google-services")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "tech.safetravel.smarttourist.smart_tourist_app"
    compileSdk = 34 // Changed from 36 to 34 for better compatibility
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17 // Updated from 1.8
        targetCompatibility = JavaVersion.VERSION_17 // Updated from 1.8
    }

    kotlinOptions {
        jvmTarget = "17" // Updated from 1.8
    }

    defaultConfig {
        applicationId = "tech.safetravel.smarttourist.smart_tourist_app"
        minSdk = flutter.minSdkVersion
        targetSdk = 34 // Changed from 36 to 34 for better compatibility
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    implementation(platform("com.google.firebase:firebase-bom:33.1.2"))
    implementation("androidx.multidex:multidex:2.0.1")
}