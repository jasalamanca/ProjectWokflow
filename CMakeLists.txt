cmake_minimum_required(VERSION 3.25 FATAL_ERROR)

project(PW VERSION 0.2.1
    LANGUAGES NONE
    DESCRIPTION "A CMake module to ease package config file creation"
    HOMEPAGE_URL "https://github.com/jasalamanca/ProjectWokflow.git")

add_custom_target(PWSources SOURCES
    CHANGELOG.md
    README.md
    LICENSE
    cmake/ProjectWorkflow.cmake
    cmake/ProjectWorkflow_Wrappers.cmake
    cmake/semver.cmake
)
