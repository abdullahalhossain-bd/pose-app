plugins {
    alias(libs.plugins.android.application)
}

android {
    namespace = "com.example.betagiesheva"
    compileSdk {
        version = release(36)
    }

    defaultConfig {
        applicationId = "com.example.betagiesheva"
        minSdk = 26
        targetSdk = 36
        versionCode = 1
        versionName = "1.0"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
}

dependencies {
    implementation("com.google.android.gms:play-services-maps:18.0.2")
    implementation("com.google.android.gms:play-services-location:21.3.0")
// Use the latest version
    implementation("com.github.bumptech.glide:glide:4.16.0")
    implementation("com.github.bumptech.glide:glide:5.0.5")
    implementation("com.github.LionZXY.T-Rex-Android:trex-offline:1.0.0")
    implementation("androidx.swiperefreshlayout:swiperefreshlayout:1.1.0")
    implementation("com.github.denzcoskun:ImageSlideshow:0.1.2")
    implementation("de.hdodenhof:circleimageview:3.1.0")
    implementation("com.airbnb.android:lottie:6.6.7")
    implementation("com.android.volley:volley:1.2.1")
    implementation(libs.appcompat)
    implementation("com.google.android.material:material:1.12.0")
    implementation(libs.activity)
    implementation(libs.constraintlayout)
    testImplementation(libs.junit)
    androidTestImplementation(libs.ext.junit)
    androidTestImplementation(libs.espresso.core)
}