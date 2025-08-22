// Plugin repositories
pluginManagement {
    repositories {
        google()
        mavenCentral()
    }
}

// Dependency repositories
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}

// Project name and modules
rootProject.name = "HelloWorld"
include(":app")