allprojects {
    repositories {
        google()
        mavenCentral()
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

// Workaround: camera-core (used by the camera_android_camerax plugin) declares
// concurrent-futures as runtime-only scope, so CallbackToFutureAdapter is
// missing from the plugin's compile classpath and javac fails attaching
// JSpecify @NonNull annotations. Force it onto that module's compile classpath.
subprojects {
    if (project.name == "camera_android_camerax") {
        project.afterEvaluate {
            dependencies.add("implementation", "androidx.concurrent:concurrent-futures:1.2.0")
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
