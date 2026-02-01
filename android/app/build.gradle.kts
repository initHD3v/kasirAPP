import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.kasirapp.pos"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_1_8.toString()
    }

    defaultConfig {
        applicationId = "com.kasirapp.pos"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val keyProperties = Properties()
            val keyPropertiesFile = rootProject.file("android/key.properties")

            if (keyPropertiesFile.exists()) {
                keyPropertiesFile.inputStream().use { keyProperties.load(it) }

                // Check if all necessary properties are set and not placeholders
                val storeFileValue = keyProperties.getProperty("storeFile")
                val storePasswordValue = keyProperties.getProperty("storePassword")
                val keyAliasValue = keyProperties.getProperty("keyAlias")
                val keyPasswordValue = keyProperties.getProperty("keyPassword")

                if (!storeFileValue.isNullOrEmpty() && storeFileValue != "<YOUR_UPLOAD_KEYSTORE_FILE_NAME>" &&
                    !storePasswordValue.isNullOrEmpty() && storePasswordValue != "<YOUR_STORE_PASSWORD>" &&
                    !keyAliasValue.isNullOrEmpty() && keyAliasValue != "<YOUR_KEY_ALIAS>" &&
                    !keyPasswordValue.isNullOrEmpty() && keyPasswordValue != "<YOUR_KEY_PASSWORD>") {
                    
                    storeFile = file(storeFileValue)
                    storePassword = storePasswordValue
                    keyAlias = keyAliasValue
                    keyPassword = keyPasswordValue
                } else {
                    println("Warning: android/key.properties exists but is incomplete or contains placeholder values. Release signing config will not be fully applied. This may affect release builds.")
                }
            } else {
                println("Warning: android/key.properties not found. Release signing config will not be applied. This may affect release builds.")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}
