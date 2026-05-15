// =================================================================
//  android/build.gradle.kts (PROJECT LEVEL)
// ⚠️ NO buildscript block — settings.gradle.kts handles all plugins
// =================================================================

allprojects {
    repositories {
        google()
        mavenCentral()
    }

    // Force consistent Kotlin versions to avoid "Metadata 2.2.0" mismatch
    configurations.all {
        resolutionStrategy {
            eachDependency {
                if (requested.group == "org.jetbrains.kotlin") {
                    useVersion("2.1.0")
                }
            }
        }
    }
}

rootProject.buildDir = file("../build")

subprojects {
    project.buildDir = file("${rootProject.buildDir}/${project.name}")
}

// 🔥 Universal Fix for plugins missing 'namespace' (Required by AGP 8.0+)
subprojects {
    afterEvaluate {
        if (project.extensions.findByName("android") != null) {
            val android = project.extensions.getByName("android")
            val getNamespace = android.javaClass.methods.find { it.name == "getNamespace" }
            val setNamespace = android.javaClass.methods.find { it.name == "setNamespace" }

            if (getNamespace != null && setNamespace != null) {
                val currentNamespace = getNamespace.invoke(android)
                if (currentNamespace == null) {
                    val manifestFile = project.file("src/main/AndroidManifest.xml")
                    if (manifestFile.exists()) {
                        val manifestXml = manifestFile.readText()
                        val packageMatch = Regex("package=[\"']([^\"']+)[\"']").find(manifestXml)
                        if (packageMatch != null) {
                            val packageName = packageMatch.groupValues[1]
                            println("Applying namespace fix for project ${project.name}: $packageName")
                            setNamespace.invoke(android, packageName)
                        }
                    }
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}