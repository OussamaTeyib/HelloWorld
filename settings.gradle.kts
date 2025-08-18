// Configure plugin repositories
pluginManagement {
    repositories {
        google()
        mavenCentral()
    }
}


// Configure dependency repositories
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}

// Project name and included modules
rootProject.name = "HelloWorld"
include(":app")