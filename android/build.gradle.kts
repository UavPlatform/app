allprojects {
    repositories {
        maven { url = uri("https://maven.aliyun.com/repository/google") }
        maven { url = uri("https://maven.aliyun.com/repository/central") }
        maven { url = uri("https://maven.aliyun.com/repository/public") }
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

// 部分插件（如 tencent_rtc_sdk）在 build.gradle 里硬编码了过低的 compileSdkVersion（31），
// 而其传递依赖（androidx.*）要求 compileSdk 33/34+，导致构建失败。
// 这里在插件求值完成后统一把 compileSdk 抬到与 :app 一致的 36。
subprojects {
    fun applyOverride() {
        val android = extensions.findByName("android") ?: return
        val intType = Integer.TYPE
        val setter = sequenceOf("setCompileSdk", "setCompileSdkVersion")
            .mapNotNull { name -> runCatching { android.javaClass.getMethod(name, intType) }.getOrNull() }
            .firstOrNull()
        setter?.invoke(android, 36)
    }
    if (state.executed) {
        applyOverride()
    } else {
        afterEvaluate { applyOverride() }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
