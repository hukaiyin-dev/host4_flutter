allprojects {
    repositories {
        google()
        mavenCentral()
        maven {
            url = uri("http://192.168.110.241:1415/repository/maven-releases/")
            isAllowInsecureProtocol = true
            content {
                includeGroup("com.host4.platform")
            }
        }
        maven { url = uri("https://jitpack.io") }
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
