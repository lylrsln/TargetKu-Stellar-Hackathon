plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    // TAMBAHKAN BARIS INI AGAR FIREBASE JALAN:
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.aplikasi_layli"
    compileSdk = 36
    
    // buildToolsVersion biarkan default saja agar aman

    defaultConfig {
        applicationId = "com.example.aplikasi_layli"
        // Menggunakan minSdk dari settingan Flutter (biasanya aman)
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = 1
        versionName = "1.0"
    }

    buildTypes {
        release {
            // PERBAIKAN DI SINI:
            // Kita matikan paksa shrinkResources agar error hilang
            isShrinkResources = false 
            isMinifyEnabled = false
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
        
        // Kita tambahkan blok debug agar saat "flutter run" juga aman
        debug {
            isShrinkResources = false
            isMinifyEnabled = false
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }
}

dependencies {
    implementation("org.jetbrains.kotlin:kotlin-stdlib:1.8.22")
}