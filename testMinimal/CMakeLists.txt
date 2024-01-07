cmake_minimum_required(VERSION 3.25 FATAL_ERROR)

# ProjectWorkflow cmake modules
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/../cmake")

project(PWMinimalTest VERSION 0.0.1
    LANGUAGES C
    DESCRIPTION "Executable that consumes LIBA"
    HOMEPAGE_URL "https://github.com/jasalamanca/ProjectWokflow.git")

set(LIBA_FIND_SEMVER_VERSION "0.0.0-rc0")
find_package(LIBA 0...<1 REQUIRED)
add_executable(MinimalTest)
target_sources(MinimalTest
    PRIVATE
    minimal_test.c)
target_link_libraries(MinimalTest PRIVATE LIBA::a)
install(TARGETS MinimalTest)

include(ProjectWorkflow)
PW_install(PACKAGE MinimalTest)

include(FeatureSummary)
message(NOTICE "\nFEATURE SUMMARY\n--------------------------")
feature_summary(WHAT ALL)
