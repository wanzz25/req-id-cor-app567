plugins {
    id("com.android.application")
    id("kotlin-android")
    // Flutter Gradle Plugin harus di-apply SETELAH plugin Android & Kotlin.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "id.wanz.reqidcor"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // Application ID unik buat REQ ID COR. Ganti kalau mau publish sendiri.
        applicationId = "id.wanz.reqidcor"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Belum ada keystore sendiri -> pakai signing debug biar `flutter build apk --release`
            // tetap jalan tanpa setup tambahan. Ganti ini kalau mau publish ke Play Store.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
