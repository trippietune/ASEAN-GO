allprojects {
    repositories {
        google()
        mavenCentral()
    }

    // Some plugins (e.g. flutter_facebook_auth) don't pin their own
    // Java/Kotlin JVM target, so they inherit whatever default toolchain
    // Gradle picks up locally — which can end up mismatched between the
    // Java and Kotlin compile tasks of the *same* module (e.g. Java 11 vs
    // Kotlin 17), a combination AGP's Kotlin compiler refuses to build.
    // Forcing every subproject to the same target the app module already
    // uses (JVM 17) keeps this consistent regardless of a given plugin's
    // own build.gradle. Applied `afterEvaluate` because the Android/Kotlin
    // extensions a plugin's own build.gradle configures aren't registered
    // yet when this root build.gradle.kts first runs.
    afterEvaluate {
        extensions.findByType<com.android.build.gradle.BaseExtension>()?.apply {
            compileOptions {
                sourceCompatibility = JavaVersion.VERSION_17
                targetCompatibility = JavaVersion.VERSION_17
            }
        }
        plugins.withType<org.jetbrains.kotlin.gradle.plugin.KotlinAndroidPluginWrapper> {
            extensions.configure<org.jetbrains.kotlin.gradle.dsl.KotlinAndroidProjectExtension> {
                compilerOptions {
                    jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
                }
            }
        }
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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
